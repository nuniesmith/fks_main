/// Module for executing run.sh commands safely
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::process::Command;
use tracing::{error, info, warn};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RunShCommand {
    pub command: String,
    pub args: Vec<String>,
    pub timeout_seconds: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RunShResponse {
    pub success: bool,
    pub exit_code: Option<i32>,
    pub stdout: String,
    pub stderr: String,
    pub duration_ms: u64,
}

#[derive(Debug, Clone)]
pub struct RunShExecutor {
    runsh_path: PathBuf,
    allowed_commands: Vec<String>,
}

impl RunShExecutor {
    pub fn new(runsh_path: Option<PathBuf>) -> anyhow::Result<Self> {
        // Default to /app/run.sh or ../run.sh relative to executable
        let default_path = if let Ok(exe) = std::env::current_exe() {
            exe.parent()
                .map(|p| p.join("../run.sh"))
                .unwrap_or_else(|| PathBuf::from("/app/run.sh"))
        } else {
            PathBuf::from("/app/run.sh")
        };

        let runsh_path = runsh_path
            .or_else(|| std::env::var("RUNSH_PATH").ok().map(PathBuf::from))
            .unwrap_or(default_path);

        // Check if file exists before canonicalizing
        if !runsh_path.exists() {
            return Err(anyhow::anyhow!("run.sh not found at: {:?}", runsh_path));
        }

        // Canonicalize path for security (only if file exists)
        let runsh_path = runsh_path
            .canonicalize()
            .map_err(|e| anyhow::anyhow!("Failed to resolve run.sh path: {}", e))?;

        // Define allowed commands (menu options from run.sh - refactored version)
        // Note: Option 12 (Exit) is not included as it's not executable
        let allowed_commands = vec![
            "1".to_string(),   // Install Tools (Docker, Minikube, Helm, Trivy)
            "2".to_string(),   // Build Base Images
            "3".to_string(),   // Build Service Images
            "4".to_string(),   // Start Services (Docker Compose)
            "5".to_string(),   // Stop Services
            "6".to_string(),   // Deploy to Kubernetes
            "7".to_string(),   // Manage Venvs (Python services)
            "8".to_string(),   // Commit & Push (All repos or services only)
            "9".to_string(),   // Analyze Codebase
            "10".to_string(),  // Check GitHub Actions Status
            "11".to_string(),  // Sync/Pull Images
        ];

        Ok(Self {
            runsh_path,
            allowed_commands,
        })
    }

    pub async fn execute(&self, command: RunShCommand) -> anyhow::Result<RunShResponse> {
        let start_time = std::time::Instant::now();

        // Validate command
        if !self.allowed_commands.contains(&command.command) {
            return Err(anyhow::anyhow!(
                "Command '{}' is not allowed. Allowed commands: {:?}",
                command.command,
                self.allowed_commands
            ));
        }

        // Build input string for interactive script
        // Since run.sh is interactive, we need to provide all expected inputs
        let mut input_parts = vec![command.command.clone()];
        
        // Add common responses for interactive prompts
        // Most commands will ask "All services (a) or specific (s)?"
        if !command.args.is_empty() {
            input_parts.extend(command.args.iter().cloned());
        } else {
            // Default to "a" for "all services" when no args provided
            // This works for most commands
            input_parts.push("a".to_string());
        }

        let input = input_parts.join("\n") + "\n";
        info!("Executing run.sh command: {} with input: {:?}", command.command, input);

        // Execute command with timeout
        let timeout_duration = command.timeout_seconds.unwrap_or(300); // Default 5 minutes
        
        let runsh_path = self.runsh_path.clone();
        let input_for_cmd = input.clone();
        
        let output = tokio::time::timeout(
            std::time::Duration::from_secs(timeout_duration),
            tokio::task::spawn_blocking(move || {
                // Use bash with here-document for reliable input
                let script = format!(
                    r#"bash -c '{} <<EOF
{}
EOF' 2>&1"#,
                    runsh_path.to_string_lossy(),
                    input_for_cmd
                );
                
                Command::new("bash")
                    .arg("-c")
                    .arg(&script)
                    .output()
            }),
        )
        .await;

        let duration_ms = start_time.elapsed().as_millis() as u64;

        match output {
            Ok(Ok(Ok(output_result))) => {
                let stdout = String::from_utf8_lossy(&output_result.stdout).to_string();
                let stderr = String::from_utf8_lossy(&output_result.stderr).to_string();
                let exit_code = output_result.status.code();

                let success = exit_code == Some(0);

                if !success {
                    warn!(
                        "run.sh command failed: exit_code={:?}, stderr={}",
                        exit_code, stderr
                    );
                }

                Ok(RunShResponse {
                    success,
                    exit_code,
                    stdout,
                    stderr,
                    duration_ms,
                })
            }
            Ok(Ok(Err(e))) => {
                error!("Failed to execute run.sh command: {}", e);
                Err(anyhow::anyhow!("Command execution failed: {}", e))
            }
            Ok(Err(e)) => {
                error!("Task join error: {}", e);
                Err(anyhow::anyhow!("Task panicked: {}", e))
            }
            Err(_) => {
                error!("run.sh command timed out after {} seconds", timeout_duration);
                Err(anyhow::anyhow!(
                    "Command timed out after {} seconds",
                    timeout_duration
                ))
            }
        }
    }

    pub fn get_allowed_commands(&self) -> &[String] {
        &self.allowed_commands
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_executor_creation() {
        // This test would require a real run.sh file
        // Skip in CI/CD environments
        if std::path::Path::new("../run.sh").exists() {
            let executor = RunShExecutor::new(Some(PathBuf::from("../run.sh")));
            assert!(executor.is_ok());
        }
    }
}

