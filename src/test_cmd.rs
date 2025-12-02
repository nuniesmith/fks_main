/// Test execution system for FKS services
use crate::preflight;
use anyhow::{Context, Result};
use colored::*;
use serde_json::Value;
use std::path::PathBuf;
use std::time::Duration;
use tokio::process::Command as TokioCommand;

#[derive(Debug, Clone)]
struct ServiceTestConfig {
    name: String,
    path: PathBuf,
    test_command: String,
    test_dependencies: Vec<String>,
    requires_gpu: bool,
    framework: String, // "fastapi", "axum", "django", etc.
}

#[derive(Debug)]
struct TestResult {
    service: String,
    success: bool,
    duration_ms: u64,
    stdout: String,
    stderr: String,
    exit_code: Option<i32>,
}

/// Run tests for services
pub async fn run_tests(
    service_filter: Option<String>,
    parallel: bool,
    coverage: bool,
) -> Result<()> {
    println!("\n{} FKS Platform Test Execution\n", "🧪".bright_cyan());
    
    // Always run pre-flight first (fail fast)
    println!("{} Running pre-flight checks first...\n", "⏳".bright_yellow());
    match preflight::run_preflight(true).await {
        Ok(_) => println!("{} Pre-flight checks passed\n", "✅".green()),
        Err(e) => {
            println!("{} Pre-flight checks failed: {}\n", "❌".red(), e);
            return Err(anyhow::anyhow!("Pre-flight checks failed, aborting tests"));
        }
    }
    
    // Load service registry and get test configurations
    let registry = load_service_registry().await?;
    let test_configs = extract_test_configs(&registry, service_filter.as_deref())?;
    
    if test_configs.is_empty() {
        println!("{} No services found matching filter\n", "⚠️".yellow());
        return Ok(());
    }
    
    println!("{} Found {} service(s) to test\n", "📋".bright_cyan(), test_configs.len());
    
    // Start test dependencies if needed
    println!("{} Starting test dependencies...\n", "⏳".bright_yellow());
    start_test_dependencies(&test_configs).await?;
    
    // Wait a bit for dependencies to be ready
    tokio::time::sleep(Duration::from_secs(2)).await;
    
    // Run tests
    let start = std::time::Instant::now();
    let results = if parallel {
        run_tests_parallel(&test_configs, coverage).await?
    } else {
        run_tests_sequential(&test_configs, coverage).await?
    };
    let total_duration = start.elapsed();
    
    // Print results
    print_test_results(&results, total_duration);
    
    // Generate coverage report if requested
    if coverage {
        generate_coverage_report(&results).await?;
    }
    
    // Summary
    let passed = results.iter().filter(|r| r.success).count();
    let failed = results.len() - passed;
    
    if failed == 0 {
        println!(
            "\n{} All tests passed! ({}/{} services)\n",
            "✅".green(),
            passed,
            results.len()
        );
        Ok(())
    } else {
        println!(
            "\n{} {} test(s) failed ({}/{} passed)\n",
            "❌".red(),
            failed,
            passed,
            results.len()
        );
        Err(anyhow::anyhow!("{} test(s) failed", failed))
    }
}

/// Extract test configurations from service registry
fn extract_test_configs(
    registry: &Value,
    service_filter: Option<&str>,
) -> Result<Vec<ServiceTestConfig>> {
    let mut configs = Vec::new();
    
    let services = registry
        .get("services")
        .and_then(|v| v.as_object())
        .context("No services found in registry")?;
    
    for (name, service) in services {
        // Apply filter if provided
        if let Some(filter) = service_filter {
            if !name.contains(filter) {
                continue;
            }
        }
        
        // Get service path (default to services/{name})
        let path = PathBuf::from(format!("services/{}", name));
        
        // Get test command (default based on framework)
        let framework = service
            .get("framework")
            .and_then(|v| v.as_str())
            .unwrap_or("fastapi")
            .to_string();
        
        let test_command = service
            .get("test_command")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string())
            .unwrap_or_else(|| {
                match framework.as_str() {
                    "fastapi" | "django" => "pytest -n auto --cov=src --cov-report=term-missing".to_string(),
                    "axum" => "cargo test --workspace --all-targets".to_string(),
                    _ => "pytest".to_string(),
                }
            });
        
        // Get test dependencies
        let test_dependencies = service
            .get("test_dependencies")
            .and_then(|v| v.as_array())
            .map(|arr| {
                arr.iter()
                    .filter_map(|v| v.as_str().map(|s| s.to_string()))
                    .collect()
            })
            .unwrap_or_default();
        
        // Get GPU requirement
        let requires_gpu = service
            .get("requires_gpu")
            .and_then(|v| v.as_bool())
            .unwrap_or(false);
        
        configs.push(ServiceTestConfig {
            name: name.clone(),
            path,
            test_command,
            test_dependencies,
            requires_gpu,
            framework,
        });
    }
    
    Ok(configs)
}

/// Start test dependencies (infrastructure services needed for testing)
async fn start_test_dependencies(configs: &[ServiceTestConfig]) -> Result<()> {
    // Collect all unique dependencies
    let mut deps: std::collections::HashSet<String> = std::collections::HashSet::new();
    for config in configs {
        for dep in &config.test_dependencies {
            deps.insert(dep.clone());
        }
    }
    
    if deps.is_empty() {
        return Ok(());
    }
    
    // For now, just check if dependencies are running
    // In the future, we could start them automatically
    let deps_vec: Vec<String> = deps.iter().cloned().collect();
    println!("  Test dependencies: {}", deps_vec.join(", "));
    
    Ok(())
}

/// Run tests in parallel
async fn run_tests_parallel(
    configs: &[ServiceTestConfig],
    coverage: bool,
) -> Result<Vec<TestResult>> {
    let mut tasks = Vec::new();
    
    for config in configs {
        let config_clone = config.clone();
        let task = tokio::spawn(async move {
            run_service_test(&config_clone, coverage).await
        });
        tasks.push((config.name.clone(), task));
    }
    
    let mut results = Vec::new();
    for (name, task) in tasks {
        match task.await {
            Ok(result) => results.push(result),
            Err(e) => {
                results.push(TestResult {
                    service: name,
                    success: false,
                    duration_ms: 0,
                    stdout: String::new(),
                    stderr: format!("Task error: {}", e),
                    exit_code: None,
                });
            }
        }
    }
    
    Ok(results)
}

/// Run tests sequentially
async fn run_tests_sequential(
    configs: &[ServiceTestConfig],
    coverage: bool,
) -> Result<Vec<TestResult>> {
    let mut results = Vec::new();
    
    for config in configs {
        let result = run_service_test(config, coverage).await;
        results.push(result);
    }
    
    Ok(results)
}

/// Run tests for a single service
async fn run_service_test(config: &ServiceTestConfig, _coverage: bool) -> TestResult {
    let start = std::time::Instant::now();
    
    // Check if service directory exists
    if !config.path.exists() {
        return TestResult {
            service: config.name.clone(),
            success: false,
            duration_ms: start.elapsed().as_millis() as u64,
            stdout: String::new(),
            stderr: format!("Service directory not found: {:?}", config.path),
            exit_code: None,
        };
    }
    
    // Parse test command
    let parts: Vec<&str> = config.test_command.split_whitespace().collect();
    if parts.is_empty() {
        return TestResult {
            service: config.name.clone(),
            success: false,
            duration_ms: start.elapsed().as_millis() as u64,
            stdout: String::new(),
            stderr: "Empty test command".to_string(),
            exit_code: None,
        };
    }
    
    let cmd = parts[0];
    let args = &parts[1..];
    
    // Execute test command
    let output = TokioCommand::new(cmd)
        .args(args)
        .current_dir(&config.path)
        .output()
        .await;
    
    let duration_ms = start.elapsed().as_millis() as u64;
    
    match output {
        Ok(output) => {
            let stdout = String::from_utf8_lossy(&output.stdout).to_string();
            let stderr = String::from_utf8_lossy(&output.stderr).to_string();
            let exit_code = output.status.code();
            let success = output.status.success();
            
            TestResult {
                service: config.name.clone(),
                success,
                duration_ms,
                stdout,
                stderr,
                exit_code,
            }
        }
        Err(e) => TestResult {
            service: config.name.clone(),
            success: false,
            duration_ms,
            stdout: String::new(),
            stderr: format!("Failed to execute test command: {}", e),
            exit_code: None,
        },
    }
}

/// Print test results
fn print_test_results(results: &[TestResult], total_duration: std::time::Duration) {
    println!("\n{} Test Results:\n", "📊".bright_cyan());
    
    for result in results {
        let status = if result.success {
            "✅ PASS".green()
        } else {
            "❌ FAIL".red()
        };
        
        println!(
            "{} {} ({:.2}s)",
            status,
            result.service.bright_white(),
            result.duration_ms as f64 / 1000.0
        );
        
        if !result.success && !result.stderr.is_empty() {
            let error_preview: String = result
                .stderr
                .lines()
                .take(3)
                .collect::<Vec<_>>()
                .join("\n");
            println!("    {}", error_preview.dimmed());
        }
    }
    
    println!("\n{}", "─".repeat(60).dimmed());
    println!(
        "Total time: {:.2}s",
        total_duration.as_secs_f64()
    );
}

/// Generate combined coverage report
async fn generate_coverage_report(_results: &[TestResult]) -> Result<()> {
    // TODO: Aggregate coverage reports from pytest-cov and tarpaulin
    // For now, just create the reports directory
    let reports_dir = PathBuf::from("reports/coverage");
    tokio::fs::create_dir_all(&reports_dir).await
        .context("Failed to create reports directory")?;
    
    println!("\n{} Coverage reports directory created: {:?}", "📈".bright_cyan(), reports_dir);
    println!("  (Coverage aggregation not yet implemented)");
    
    Ok(())
}

/// Load service registry JSON
async fn load_service_registry() -> Result<Value> {
    // Try multiple possible paths
    let possible_paths = vec![
        "services/config/service_registry.json",
        "../services/config/service_registry.json",
        "../../services/config/service_registry.json",
        "/app/services/config/service_registry.json",
    ];
    
    for path in possible_paths {
        if std::path::Path::new(path).exists() {
            let content = tokio::fs::read_to_string(path).await
                .with_context(|| format!("Failed to read registry at {}", path))?;
            let registry: Value = serde_json::from_str(&content)
                .with_context(|| format!("Failed to parse registry JSON at {}", path))?;
            return Ok(registry);
        }
    }
    
    Err(anyhow::anyhow!("Service registry not found in any expected location"))
}
