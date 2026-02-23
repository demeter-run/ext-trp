use async_trait::async_trait;
use pingora::http::Method;
use pingora::Result;
use pingora::{
    http::ResponseHeader,
    proxy::{ProxyHttp, Session},
    upstreams::peer::HttpPeer,
};
use pingora_limits::rate::Rate;
use std::sync::Arc;
use tracing::info;

use crate::config::Config;
use crate::{Consumer, State, Tier};

static DMTR_API_KEY: &str = "dmtr-api-key";

pub struct TrpProxy {
    state: Arc<State>,
    config: Arc<Config>,
}
impl TrpProxy {
    pub fn new(state: Arc<State>, config: Arc<Config>) -> Self {
        Self { state, config }
    }

    async fn has_limiter(&self, consumer: &Consumer) -> bool {
        let rate_limiter_map = self.state.limiter.read().await;
        rate_limiter_map.get(&consumer.key).is_some()
    }

    async fn add_limiter(&self, consumer: &Consumer, tier: &Tier) {
        let rates = tier
            .rates
            .iter()
            .map(|r| (r.clone(), Rate::new(r.interval)))
            .collect();

        self.state
            .limiter
            .write()
            .await
            .insert(consumer.key.clone(), rates);
    }

    async fn limiter(&self, consumer: &Consumer) -> Result<bool> {
        let tiers = self.state.tiers.read().await.clone();
        let tier = tiers.get(&consumer.tier);
        if tier.is_none() {
            return Ok(true);
        }
        let tier = tier.unwrap();

        if !self.has_limiter(consumer).await {
            self.add_limiter(consumer, tier).await;
        }

        let rate_limiter_map = self.state.limiter.read().await;
        let rates = rate_limiter_map.get(&consumer.key).unwrap();

        if rates
            .iter()
            .any(|(t, r)| r.observe(&consumer.key, 1) > t.limit)
        {
            return Ok(true);
        }

        Ok(false)
    }

    fn extract_key(&self, session: &Session) -> Option<String> {
        session
            .get_header(DMTR_API_KEY)
            .map(|v| v.to_str().unwrap().to_string())
    }

    async fn respond_health(&self, session: &mut Session, ctx: &mut Context) {
        ctx.is_health_request = true;
        session.set_keepalive(None);
        session
            .write_response_body(Some("OK".into()), true)
            .await
            .unwrap();
        let header = Box::new(ResponseHeader::build(200, None).unwrap());
        session.write_response_header(header, true).await.unwrap();
    }
}

#[derive(Debug, Default)]
pub struct Context {
    instance: String,
    consumer: Consumer,
    is_health_request: bool,
}

#[async_trait]
impl ProxyHttp for TrpProxy {
    type CTX = Context;
    fn new_ctx(&self) -> Self::CTX {
        Context::default()
    }

    async fn request_filter(&self, session: &mut Session, ctx: &mut Self::CTX) -> Result<bool>
    where
        Self::CTX: Send + Sync,
    {
        if session.req_header().method == Method::OPTIONS {
            ctx.instance = self.config.trp_instance.clone();
            return Ok(false);
        }
        let path = session.req_header().uri.path();
        if path == self.config.health_endpoint {
            self.respond_health(session, ctx).await;
            return Ok(true);
        }

        let Some(key) = self.extract_key(session) else {
            session.respond_error(401).await?;
            return Ok(true);
        };

        let Some(consumer) = self.state.get_consumer(&key).await else {
            session.respond_error(401).await?;
            return Ok(true);
        };

        if consumer.network != self.config.network {
            session.respond_error(401).await?;
            return Ok(true);
        }

        ctx.consumer = consumer;
        ctx.instance = self.config.trp_instance.clone();

        if self.limiter(&ctx.consumer).await? {
            session.respond_error(429).await?;
            return Ok(true);
        }

        Ok(false)
    }

    async fn upstream_peer(
        &self,
        _session: &mut Session,
        ctx: &mut Self::CTX,
    ) -> Result<Box<HttpPeer>> {
        let http_peer = HttpPeer::new(&ctx.instance, false, String::default());
        Ok(Box::new(http_peer))
    }

    async fn logging(
        &self,
        session: &mut Session,
        _e: Option<&pingora::Error>,
        ctx: &mut Self::CTX,
    ) {
        if !ctx.is_health_request {
            let response_code = session
                .response_written()
                .map_or(0, |resp| resp.status.as_u16());

            info!(
                "{} response code: {response_code}",
                self.request_summary(session, ctx)
            );

            self.state.metrics.inc_http_total_request(
                &ctx.consumer,
                &self.config.proxy_namespace,
                &ctx.instance,
                &response_code,
            );
        }
    }
}
