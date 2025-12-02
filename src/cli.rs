/// CLI command definitions for fks_main
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "fks_main")]
#[command(about = "FKS Main Orchestration Service - CLI and API server")]
#[command(version = "1.0.0")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Run pre-flight checks to validate platform readiness
    Preflight {
        /// Run full pre-flight including smoke integration test
        #[arg(long)]
        full: bool,
    },
    /// Run tests for services
    Test {
        /// Run tests for a specific service only
        #[arg(long)]
        service: Option<String>,
        /// Run tests in parallel (default: true)
        #[arg(long, default_value = "true")]
        parallel: bool,
        /// Generate coverage reports
        #[arg(long)]
        coverage: bool,
    },
}
