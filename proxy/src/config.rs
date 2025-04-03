use std::{env, path::PathBuf, time::Duration};

#[derive(Debug, Clone)]
pub struct Config {
    pub proxy_addr: String,
    pub proxy_namespace: String,
    pub proxy_tiers_path: PathBuf,
    pub proxy_tiers_poll_interval: Duration,
    pub prometheus_addr: String,
    pub ssl_crt_path: String,
    pub ssl_key_path: String,
    pub trp_port: u16,
    pub trp_dns: String,
    pub health_endpoint: String,
    pub network: String,
}
impl Config {
    pub fn new() -> Self {
        Self {
            network: env::var("NETWORK").expect("PROXY_ADDR must be set"),
            proxy_addr: env::var("PROXY_ADDR").expect("PROXY_ADDR must be set"),
            proxy_namespace: env::var("PROXY_NAMESPACE").expect("PROXY_NAMESPACE must be set"),
            proxy_tiers_path: env::var("PROXY_TIERS_PATH")
                .map(|v| v.into())
                .expect("PROXY_TIERS_PATH must be set"),
            proxy_tiers_poll_interval: env::var("PROXY_TIERS_POLL_INTERVAL")
                .map(|v| {
                    Duration::from_secs(
                        v.parse::<u64>()
                            .expect("PROXY_TIERS_POLL_INTERVAL must be a number in seconds. eg: 2"),
                    )
                })
                .unwrap_or(Duration::from_secs(2)),
            prometheus_addr: env::var("PROMETHEUS_ADDR").expect("PROMETHEUS_ADDR must be set"),
            ssl_crt_path: env::var("SSL_CRT_PATH").expect("SSL_CRT_PATH must be set"),
            ssl_key_path: env::var("SSL_KEY_PATH").expect("SSL_KEY_PATH must be set"),
            trp_port: env::var("TRP_PORT")
                .expect("TRP_PORT must be set")
                .parse()
                .expect("TRP_PORT must a number"),
            trp_dns: env::var("TRP_DNS").expect("TRP_DNS must be set"),
            health_endpoint: "/dmtr_health".to_string(),
        }
    }

    pub fn instance(&self) -> String {
        format!("trp-{}.{}:{}", self.network, self.trp_dns, self.trp_port)
    }
}
impl Default for Config {
    fn default() -> Self {
        Self::new()
    }
}
