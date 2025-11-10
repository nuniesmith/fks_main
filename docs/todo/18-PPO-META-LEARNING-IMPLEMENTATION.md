# PPO Meta-Learning Implementation - Complete Task Guide
## AI Agent Instructions for Dynamic Model Selection in FKS

**Date**: 2025-01-XX  
**Status**: Ready for Implementation  
**Purpose**: Step-by-step guide for AI agents to implement PPO meta-learning for dynamic strategy/model selection  
**Estimated Effort**: 250-350 hours over 6-8 weeks  
**Prerequisites**: fks_training service, fks_data historical data, fks_app strategies

---

## 🎯 Project Overview

**Objective**: Implement Proximal Policy Optimization (PPO) meta-learning in fks_training to dynamically select among trading strategies/models based on market conditions, improving signal accuracy by 15-25% through adaptive regime-aware selection.

**Key Deliverables**:
1. Dual-head PPO architecture for directional + auxiliary rewards
2. 22D feature vector adapted to FKS data sources
3. Trading environment for stock/crypto trading (buy/sell/hold actions)
4. Complete PPO training pipeline with from-scratch implementation
5. Dynamic strategy selection integrated with fks_app and fks_ai
6. Hybrid PPO-LangGraph for agentic routing in multi-agent debates
7. Integration with chaos engineering for resilience testing

**Success Criteria**:
- >65% directional accuracy (vs. 58% baseline)
- 15-25% signal accuracy improvement
- Adaptive selection based on market regimes
- Integration with fks_ai multi-agent system
- Resilience tested via chaos engineering
- Trading environment works with yfinance and fks_data
- PPO training completes successfully on real stock data

**Practical Trading Performance** (based on research):
- **Directional Accuracy**: 50-65% (realistic expectation)
- **Annualized Returns**: 10-30% (backtest, before slippage)
- **Sharpe Ratio**: 0.5-1.5 (risk-adjusted returns)
- **Drawdown**: 10-20% (maximum loss from peak)
- **Real Performance**: 10-15% returns (after slippage and fees)

---

## 📋 Phase 1: PPO Architecture Setup (Weeks 1-2)

### Task 1.1: Implement Dual-Head PPO Architecture with Shared Backbone

**Objective**: Create dual-head PPO architecture with shared backbone for efficient feature extraction and directional + auxiliary rewards

**Key Concepts**:
- **Shared Backbone**: Common feature extractor for both actor and critic (efficient, reduces parameters)
- **Actor Head**: Policy network outputting action probabilities (strategy selection)
- **Critic Head**: Value network estimating state value (auxiliary rewards)
- **Clipped Surrogate Objective**: Prevents large policy updates for stability
- **GAE (Generalized Advantage Estimation)**: Reduces variance in advantage estimates

**Actions for AI Agent**:

1. **Create Shared Backbone Network**:
   ```
   File: repo/training/src/ppo/networks.py
   Content:
   import torch
   import torch.nn as nn
   import torch.nn.functional as F
   from typing import Tuple
   
   class BackboneNetwork(nn.Module):
       """Shared backbone network for feature extraction"""
       
       def __init__(
           self,
           in_features: int = 22,
           hidden_dimensions: int = 128,
           out_features: int = 64,
           dropout: float = 0.2
       ):
           super().__init__()
           self.layer1 = nn.Linear(in_features, hidden_dimensions)
           self.layer2 = nn.Linear(hidden_dimensions, hidden_dimensions)
           self.layer3 = nn.Linear(hidden_dimensions, out_features)
           self.dropout = nn.Dropout(dropout)
       
       def forward(self, x: torch.Tensor) -> torch.Tensor:
           """Forward pass through shared backbone"""
           x = F.relu(self.layer1(x))
           x = self.dropout(x)
           x = F.relu(self.layer2(x))
           x = self.dropout(x)
           x = self.layer3(x)
           return x
   ```

2. **Create Dual-Head Actor-Critic Network**:
   ```
   File: repo/training/src/ppo/policy_network.py
   Content:
   import torch
   import torch.nn as nn
   import torch.nn.functional as F
   from torch.distributions import Categorical
   from typing import Tuple
   from .networks import BackboneNetwork
   
   class DualHeadPPOPolicy(nn.Module):
       """Dual-head PPO policy with shared backbone for trading model selection"""
       
       def __init__(
           self,
           feature_dim: int = 22,
           hidden_dim: int = 128,
           num_actions: int = 10,  # Number of strategies/models
           dropout: float = 0.2
       ):
           super().__init__()
           
           # Shared backbone for feature extraction
           self.backbone = BackboneNetwork(
               in_features=feature_dim,
               hidden_dimensions=hidden_dim,
               out_features=hidden_dim,
               dropout=dropout
           )
           
           # Actor head (policy) - outputs action logits (before softmax)
           self.actor = nn.Sequential(
               nn.Linear(hidden_dim, hidden_dim // 2),
               nn.ReLU(),
               nn.Dropout(dropout),
               nn.Linear(hidden_dim // 2, num_actions)
               # Note: No softmax here - use in forward/get_action for numerical stability
           )
           
           # Critic head (value) - outputs state value
           self.critic = nn.Sequential(
               nn.Linear(hidden_dim, hidden_dim // 2),
               nn.ReLU(),
               nn.Dropout(dropout),
               nn.Linear(hidden_dim // 2, 1)
           )
       
       def forward(self, state: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor]:
           """Forward pass through network
        
           Args:
               state: Input state tensor (batch_size, feature_dim)
           
           Returns:
               action_logits: Action logits before softmax (batch_size, num_actions)
               value: State value estimate (batch_size, 1)
           """
           # Shared feature extraction
           features = self.backbone(state)
           
           # Actor and critic heads
           action_logits = self.actor(features)
           value = self.critic(features)
           
           return action_logits, value
       
       def get_action(
           self,
           state: torch.Tensor,
           deterministic: bool = False
       ) -> Tuple[int, float, torch.Tensor, torch.Tensor]:
           """Sample action from policy
        
           Args:
               state: Input state tensor (1, feature_dim) or (feature_dim,)
               deterministic: If True, return most likely action; if False, sample
        
           Returns:
               action: Selected action (int)
               value: State value estimate (float)
               log_prob: Log probability of action (torch.Tensor)
               action_probs: Action probabilities (torch.Tensor)
           """
           # Ensure state is batched
           if state.dim() == 1:
               state = state.unsqueeze(0)
           
           # Forward pass
           action_logits, value = self.forward(state)
           
           # Apply softmax to get probabilities
           action_probs = F.softmax(action_logits, dim=-1)
           
           # Create distribution
           dist = Categorical(action_probs)
           
           # Sample or take most likely
           if deterministic:
               action = torch.argmax(action_probs, dim=-1)
           else:
               action = dist.sample()
           
           log_prob = dist.log_prob(action)
           
           return action.item(), value.item(), log_prob, action_probs.squeeze(0)
   ```

2. **Create Data Collection (Forward Pass) with GAE**:
   ```
   File: repo/training/src/ppo/data_collection.py
   Content:
   import torch
   import torch.nn.functional as F
   from torch.distributions import Categorical
   from typing import List, Tuple, Dict, Any
   import numpy as np
   from loguru import logger
   from .policy_network import DualHeadPPOPolicy
   
   def forward_pass(
       env,
       agent: DualHeadPPOPolicy,
       gamma: float = 0.99,
       max_steps: int = 1000
   ) -> Tuple[float, torch.Tensor, torch.Tensor, torch.Tensor, torch.Tensor, torch.Tensor]:
       """Collect trajectory data from environment
       
       Args:
           env: Trading environment (Gymnasium-compatible)
           agent: PPO policy network
           gamma: Discount factor
           max_steps: Maximum steps per episode
       
       Returns:
           total_reward: Sum of rewards in episode
           states: Collected states (n_steps, feature_dim)
           actions: Collected actions (n_steps,)
           logprobs: Log probabilities of actions (n_steps,)
           values: State values (n_steps,)
           rewards: Collected rewards (n_steps,)
       """
       states, actions, logprobs, values, rewards = [], [], [], [], []
       
       # Reset environment
       state, info = env.reset()
       done = False
       step = 0
       
       agent.train()  # Set to training mode
       
       while not done and step < max_steps:
           # Convert state to tensor
           state_t = torch.FloatTensor(state).unsqueeze(0)
           
           # Get action from policy
           action_logits, value = agent(state_t)
           action_probs = F.softmax(action_logits, dim=-1)
           dist = Categorical(action_probs)
           action = dist.sample()
           logp = dist.log_prob(action)
           
           # Take action in environment
           next_state, reward, terminated, truncated, info = env.step(action.item())
           done = terminated or truncated
           
           # Store trajectory data
           states.append(state_t)
           actions.append(action)
           logprobs.append(logp)
           values.append(value)
           rewards.append(reward)
           
           state = next_state
           step += 1
       
       # Convert to tensors
       states = torch.cat(states)
       actions = torch.cat(actions)
       logprobs = torch.cat(logprobs)
       values = torch.cat(values).squeeze(-1)
       rewards = torch.tensor(rewards, dtype=torch.float32)
       
       # Compute returns (discounted cumulative rewards)
       returns = compute_returns(rewards, gamma)
       
       # Normalize returns for stability
       returns = (returns - returns.mean()) / (returns.std() + 1e-8)
       
       # Compute advantages using GAE
       advantages = compute_gae_advantages(rewards, values, gamma, lambda_gae=0.95)
       
       # Normalize advantages
       advantages = (advantages - advantages.mean()) / (advantages.std() + 1e-8)
       
       total_reward = rewards.sum().item()
       
       return total_reward, states, actions, logprobs, advantages, returns
   
   def compute_returns(rewards: torch.Tensor, gamma: float) -> torch.Tensor:
       """Compute discounted returns
       
       Formula: G_t = r_t + γ * G_{t+1}
       """
       returns = []
       G = 0
       
       for r in reversed(rewards):
           G = r + gamma * G
           returns.insert(0, G)
       
       return torch.tensor(returns, dtype=torch.float32)
   
   def compute_gae_advantages(
       rewards: torch.Tensor,
       values: torch.Tensor,
       gamma: float,
       lambda_gae: float = 0.95
   ) -> torch.Tensor:
       """Compute advantages using Generalized Advantage Estimation (GAE)
       
       Formula: 
       δ_t = r_t + γ * V(s_{t+1}) - V(s_t)
       Â_t = δ_t + (γ * λ) * Â_{t+1}
       
       This reduces variance compared to simple advantage estimation.
       """
       advantages = []
       gae = 0
       
       # Append bootstrap value for last step
       next_value = 0  # Assuming episode ended
       values_plus_next = torch.cat([values, torch.tensor([next_value])])
       
       for t in reversed(range(len(rewards))):
           # TD error
           delta = rewards[t] + gamma * values_plus_next[t + 1] - values_plus_next[t]
           
           # GAE
           gae = delta + gamma * lambda_gae * gae
           advantages.insert(0, gae)
       
       return torch.tensor(advantages, dtype=torch.float32)
   ```

3. **Create PPO Trainer with Clipping**:
   ```
   File: repo/training/src/ppo/trainer.py
   Content:
   import torch
   import torch.optim as optim
   import torch.nn.functional as F
   from torch.utils.data import TensorDataset, DataLoader
   from torch.distributions import Categorical
   from typing import List, Dict, Any, Tuple
   import numpy as np
   from loguru import logger
   from .policy_network import DualHeadPPOPolicy
   
   class PPOTrainer:
       """PPO trainer with clipped surrogate objective for meta-learning"""
       
       def __init__(
           self,
           policy: DualHeadPPOPolicy,
           lr: float = 0.001,  # Learning rate (from research: 0.001 works well)
           gamma: float = 0.99,  # Discount factor
           epsilon: float = 0.2,  # Clipping parameter (from research: 0.2 is standard)
           value_coef: float = 0.5,  # Value loss coefficient
           entropy_coef: float = 0.01,  # Entropy coefficient (encourages exploration)
           max_grad_norm: float = 0.5,  # Gradient clipping
           ppo_epochs: int = 10,  # Number of PPO update epochs
           batch_size: int = 128  # Batch size for updates
       ):
           self.policy = policy
           self.optimizer = optim.Adam(self.policy.parameters(), lr=lr)
           
           self.gamma = gamma
           self.epsilon = epsilon  # Clip range [1-ε, 1+ε]
           self.value_coef = value_coef
           self.entropy_coef = entropy_coef
           self.max_grad_norm = max_grad_norm
           self.ppo_epochs = ppo_epochs
           self.batch_size = batch_size
       
       def update_policy(
           self,
           states: torch.Tensor,
           actions: torch.Tensor,
           old_log_probs: torch.Tensor,
           advantages: torch.Tensor,
           returns: torch.Tensor
       ) -> Dict[str, float]:
           """Update policy using PPO with clipped surrogate objective
           
           PPO Algorithm:
           1. Collect trajectories under current policy
           2. Compute advantages using GAE
           3. For K epochs:
              a. Create mini-batches
              b. Compute policy ratio: r(θ) = π_θ(a|s) / π_θ_old(a|s)
              c. Compute clipped surrogate: L^CLIP = min(r * A, clip(r, 1-ε, 1+ε) * A)
              d. Compute value loss: L^VF = (V(s) - R)^2
              e. Compute entropy bonus: L^S = -H(π(·|s))
              f. Total loss: L = -L^CLIP + c_vf * L^VF - c_s * L^S
              g. Update policy with gradient descent
           
           Args:
               states: Collected states (n_steps, feature_dim)
               actions: Collected actions (n_steps,)
               old_log_probs: Old log probabilities (n_steps,)
               advantages: Computed advantages (n_steps,)
               returns: Computed returns (n_steps,)
           
           Returns:
               Dictionary with loss statistics
           """
           # Create dataset for mini-batching
           dataset = TensorDataset(states, actions, old_log_probs, advantages, returns)
           loader = DataLoader(dataset, batch_size=self.batch_size, shuffle=True)
           
           total_pol_loss = 0.0
           total_val_loss = 0.0
           total_entropy = 0.0
           total_loss = 0.0
           n_updates = 0
           
           # Multiple epochs of updates on same data (PPO key feature)
           for epoch in range(self.ppo_epochs):
               for batch in loader:
                   s, a, old_lp, adv_batch, ret = batch
                   
                   # Forward pass through policy
                   action_logits, v_pred = self.policy(s)
                   action_probs = F.softmax(action_logits, dim=-1)
                   dist = Categorical(action_probs)
                   
                   # Compute new log probabilities
                   new_logp = dist.log_prob(a)
                   
                   # Compute entropy (for exploration bonus)
                   entropy = dist.entropy().mean()
                   
                   # Compute ratio: r(θ) = π_θ(a|s) / π_θ_old(a|s)
                   # In log space: ratio = exp(new_logp - old_logp)
                   ratio = torch.exp(new_logp - old_lp.detach())
                   
                   # Clipped surrogate objective
                   # L^CLIP(θ) = E[min(r(θ) * A, clip(r(θ), 1-ε, 1+ε) * A)]
                   surr1 = ratio * adv_batch.detach()
                   surr2 = torch.clamp(ratio, 1 - self.epsilon, 1 + self.epsilon) * adv_batch.detach()
                   pol_loss = -torch.min(surr1, surr2).mean()
                   
                   # Value loss (squared error between predicted and actual returns)
                   # Use smooth L1 loss for robustness (from research)
                   val_loss = F.smooth_l1_loss(v_pred.squeeze(-1), ret.detach()).mean()
                   
                   # Total loss
                   # L = -L^CLIP + c_vf * L^VF - c_s * L^S
                   loss = pol_loss + self.value_coef * val_loss - self.entropy_coef * entropy
                   
                   # Backward pass
                   self.optimizer.zero_grad()
                   loss.backward()
                   
                   # Gradient clipping (prevents exploding gradients)
                   torch.nn.utils.clip_grad_norm_(self.policy.parameters(), self.max_grad_norm)
                   
                   self.optimizer.step()
                   
                   # Track statistics
                   total_pol_loss += pol_loss.item()
                   total_val_loss += val_loss.item()
                   total_entropy += entropy.item()
                   total_loss += loss.item()
                   n_updates += 1
           
           # Average statistics
           avg_pol_loss = total_pol_loss / n_updates
           avg_val_loss = total_val_loss / n_updates
           avg_entropy = total_entropy / n_updates
           avg_loss = total_loss / n_updates
           
           logger.info(
               f"PPO update complete: "
               f"pol_loss={avg_pol_loss:.4f}, "
               f"val_loss={avg_val_loss:.4f}, "
               f"entropy={avg_entropy:.4f}, "
               f"total_loss={avg_loss:.4f}"
           )
           
           return {
               "policy_loss": avg_pol_loss,
               "value_loss": avg_val_loss,
               "entropy": avg_entropy,
               "total_loss": avg_loss,
               "n_updates": n_updates
           }
   ```

4. **Create Complete Training Loop**:
   ```
   File: repo/training/src/ppo/training_loop.py
   Content:
   import torch
   import numpy as np
   from typing import Dict, Any, Optional
   from loguru import logger
   import mlflow
   from pathlib import Path
   
   from .policy_network import DualHeadPPOPolicy
   from .trainer import PPOTrainer
   from .data_collection import forward_pass, compute_returns, compute_gae_advantages
   
   def evaluate(
       env,
       agent: DualHeadPPOPolicy,
       n_episodes: int = 10,
       deterministic: bool = True
   ) -> float:
       """Evaluate agent performance
       
       Args:
           env: Trading environment
           agent: PPO policy network
           n_episodes: Number of evaluation episodes
           deterministic: If True, use deterministic policy (no exploration)
       
       Returns:
           Average episode reward
       """
       agent.eval()  # Set to evaluation mode
       episode_rewards = []
       
       with torch.no_grad():
           for _ in range(n_episodes):
               state, info = env.reset()
               done = False
               total_reward = 0.0
               step = 0
               
               while not done and step < 1000:
                   state_t = torch.FloatTensor(state).unsqueeze(0)
                   action, value, _, _ = agent.get_action(state_t, deterministic=deterministic)
                   
                   next_state, reward, terminated, truncated, info = env.step(action)
                   done = terminated or truncated
                   
                   total_reward += reward
                   state = next_state
                   step += 1
               
               episode_rewards.append(total_reward)
       
       agent.train()  # Reset to training mode
       return np.mean(episode_rewards)
   
   def run_ppo_training(
       env_train,
       env_test,
       feature_dim: int = 22,
       num_actions: int = 10,
       max_episodes: int = 1000,
       threshold: float = 475.0,  # Reward threshold for early stopping
       lr: float = 0.001,
       gamma: float = 0.99,
       epsilon: float = 0.2,
       value_coef: float = 0.5,
       entropy_coef: float = 0.01,
       ppo_epochs: int = 10,
       batch_size: int = 128,
       max_grad_norm: float = 0.5,
       log_interval: int = 10,
       save_interval: int = 100,
       model_save_path: Optional[str] = None,
       use_mlflow: bool = True
   ) -> Dict[str, Any]:
       """Complete PPO training loop
       
       Training Process:
       1. Initialize policy and trainer
       2. For each episode:
          a. Collect trajectory using current policy
          b. Compute returns and advantages (GAE)
          c. Update policy using PPO (multiple epochs on batches)
          d. Evaluate on test environment
          e. Log metrics
          f. Save model periodically
       3. Early stop if threshold reached
       
       Args:
           env_train: Training environment
           env_test: Test environment for evaluation
           feature_dim: Dimension of feature vector (22D)
           num_actions: Number of actions (strategies/models)
           max_episodes: Maximum training episodes
           threshold: Reward threshold for early stopping
           lr: Learning rate
           gamma: Discount factor
           epsilon: PPO clipping parameter
           value_coef: Value loss coefficient
           entropy_coef: Entropy coefficient
           ppo_epochs: Number of PPO update epochs
           batch_size: Batch size for updates
           max_grad_norm: Maximum gradient norm for clipping
           log_interval: Log metrics every N episodes
           save_interval: Save model every N episodes
           model_save_path: Path to save model
           use_mlflow: Whether to use MLflow for tracking
       
       Returns:
           Training statistics and final model
       """
       # Initialize policy and trainer
       logger.info("Initializing PPO policy and trainer...")
       policy = DualHeadPPOPolicy(
           feature_dim=feature_dim,
           hidden_dim=128,
           num_actions=num_actions,
           dropout=0.2
       )
       
       trainer = PPOTrainer(
           policy=policy,
           lr=lr,
           gamma=gamma,
           epsilon=epsilon,
           value_coef=value_coef,
           entropy_coef=entropy_coef,
           max_grad_norm=max_grad_norm,
           ppo_epochs=ppo_epochs,
           batch_size=batch_size
       )
       
       # MLflow tracking
       if use_mlflow:
           mlflow.set_experiment("ppo_meta_learning")
           mlflow.start_run()
           mlflow.log_params({
               "feature_dim": feature_dim,
               "num_actions": num_actions,
               "lr": lr,
               "gamma": gamma,
               "epsilon": epsilon,
               "value_coef": value_coef,
               "entropy_coef": entropy_coef,
               "ppo_epochs": ppo_epochs,
               "batch_size": batch_size,
               "max_grad_norm": max_grad_norm
           })
       
       # Training statistics
       training_stats = {
           "episode_rewards": [],
           "test_rewards": [],
           "policy_losses": [],
           "value_losses": [],
           "entropies": [],
           "best_test_reward": -np.inf,
           "episodes_trained": 0
       }
       
       # Model save path
       if model_save_path is None:
           model_save_path = "./models/ppo/ppo_meta_learning.pt"
       Path(model_save_path).parent.mkdir(parents=True, exist_ok=True)
       
       logger.info(f"Starting PPO training for {max_episodes} episodes...")
       logger.info(f"Early stop threshold: {threshold}")
       
       # Training loop
       for episode in range(1, max_episodes + 1):
           # Collect trajectory
           train_reward, states, actions, old_log_probs, advantages, returns = forward_pass(
               env_train,
               policy,
               gamma=gamma,
               max_steps=1000
           )
           
           # Update policy
           update_stats = trainer.update_policy(
               states=states,
               actions=actions,
               old_log_probs=old_log_probs,
               advantages=advantages,
               returns=returns
           )
           
           # Evaluate on test environment
           test_reward = evaluate(env_test, policy, n_episodes=5, deterministic=True)
           
           # Update statistics
           training_stats["episode_rewards"].append(train_reward)
           training_stats["test_rewards"].append(test_reward)
           training_stats["policy_losses"].append(update_stats["policy_loss"])
           training_stats["value_losses"].append(update_stats["value_loss"])
           training_stats["entropies"].append(update_stats["entropy"])
           training_stats["episodes_trained"] = episode
           
           # Track best model
           if test_reward > training_stats["best_test_reward"]:
               training_stats["best_test_reward"] = test_reward
               torch.save(policy.state_dict(), model_save_path)
               logger.info(f"✅ New best model saved (test reward: {test_reward:.2f})")
           
           # Log metrics
           if episode % log_interval == 0:
               avg_train_reward = np.mean(training_stats["episode_rewards"][-log_interval:])
               avg_test_reward = np.mean(training_stats["test_rewards"][-log_interval:])
               avg_pol_loss = np.mean(training_stats["policy_losses"][-log_interval:])
               avg_val_loss = np.mean(training_stats["value_losses"][-log_interval:])
               avg_entropy = np.mean(training_stats["entropies"][-log_interval:])
               
               logger.info(
                   f"Episode {episode}/{max_episodes} | "
                   f"Train Reward: {avg_train_reward:.2f} | "
                   f"Test Reward: {avg_test_reward:.2f} | "
                   f"Pol Loss: {avg_pol_loss:.4f} | "
                   f"Val Loss: {avg_val_loss:.4f} | "
                   f"Entropy: {avg_entropy:.4f}"
               )
               
               if use_mlflow:
                   mlflow.log_metrics({
                       "train_reward": avg_train_reward,
                       "test_reward": avg_test_reward,
                       "policy_loss": avg_pol_loss,
                       "value_loss": avg_val_loss,
                       "entropy": avg_entropy
                   }, step=episode)
           
           # Save model periodically
           if episode % save_interval == 0:
               checkpoint_path = f"{model_save_path}.checkpoint_{episode}"
               torch.save({
                   "episode": episode,
                   "policy_state_dict": policy.state_dict(),
                   "optimizer_state_dict": trainer.optimizer.state_dict(),
                   "training_stats": training_stats
               }, checkpoint_path)
               logger.info(f"Checkpoint saved: {checkpoint_path}")
           
           # Early stopping
           if test_reward >= threshold:
               logger.info(f"✅ Early stopping: Test reward {test_reward:.2f} >= threshold {threshold}")
               break
       
       # Final evaluation
       logger.info("Running final evaluation...")
       final_test_reward = evaluate(env_test, policy, n_episodes=10, deterministic=True)
       training_stats["final_test_reward"] = final_test_reward
       
       logger.info(f"Training completed!")
       logger.info(f"Episodes trained: {training_stats['episodes_trained']}")
       logger.info(f"Best test reward: {training_stats['best_test_reward']:.2f}")
       logger.info(f"Final test reward: {final_test_reward:.2f}")
       
       if use_mlflow:
           mlflow.log_metric("final_test_reward", final_test_reward)
           mlflow.log_metric("best_test_reward", training_stats["best_test_reward"])
           mlflow.log_artifact(model_save_path, "model")
           mlflow.end_run()
       
       return {
           "policy": policy,
           "trainer": trainer,
           "training_stats": training_stats,
           "model_path": model_save_path
       }
   ```

**Deliverable**: Complete PPO training pipeline with from-scratch implementation

**Success Criteria**: 
- Policy network trains successfully
- Dual heads work correctly (actor + critic)
- Gradients flow correctly
- Training loop completes without errors
- Test reward improves over time
- Model saves and loads correctly

**Key Implementation Details**:
- **Shared Backbone**: Efficient feature extraction for both actor and critic
- **GAE**: Generalized Advantage Estimation reduces variance
- **Clipping**: Prevents large policy updates (ε=0.2)
- **Multi-Epoch Updates**: Reuses trajectories for efficiency (10 epochs)
- **Gradient Clipping**: Prevents exploding gradients (max_norm=0.5)
- **Entropy Bonus**: Encourages exploration (entropy_coef=0.01)
- **Early Stopping**: Stops when threshold reached (test_reward >= 475)

5. **Create Complete Training Script with Trading Environment**:
   ```
   File: repo/training/src/ppo/train_trading_ppo.py
   Content:
   """
   Complete PPO training script for stock trading
   
   Usage:
       python -m training.src.ppo.train_trading_ppo \
           --ticker AAPL \
           --start-date 2020-01-01 \
           --end-date 2025-11-01 \
           --max-episodes 1000 \
           --data-source yfinance
   """
   import argparse
   import torch
   import numpy as np
   from loguru import logger
   from pathlib import Path
   import mlflow
   
   from .trading_env import TradingEnv
   from .policy_network import DualHeadPPOPolicy
   from .trainer import PPOTrainer
   from .data_collection import forward_pass
   from .training_loop import evaluate, run_ppo_training
   
   def split_data_dates(start_date: str, end_date: str, train_ratio: float = 0.8):
       """Split date range into train and test periods"""
       from datetime import datetime, timedelta
       
       start = datetime.strptime(start_date, "%Y-%m-%d")
       end = datetime.strptime(end_date, "%Y-%m-%d")
       total_days = (end - start).days
       train_days = int(total_days * train_ratio)
       
       train_end = start + timedelta(days=train_days)
       test_start = train_end + timedelta(days=1)
       
       return (
           start_date,
           train_end.strftime("%Y-%m-%d"),
           test_start.strftime("%Y-%m-%d"),
           end_date
       )
   
   def main():
       parser = argparse.ArgumentParser(description="Train PPO agent for stock trading")
       parser.add_argument("--ticker", type=str, default="AAPL", help="Stock ticker symbol")
       parser.add_argument("--start-date", type=str, default="2020-01-01", help="Start date (YYYY-MM-DD)")
       parser.add_argument("--end-date", type=str, default="2025-11-01", help="End date (YYYY-MM-DD)")
       parser.add_argument("--data-source", type=str, default="yfinance", choices=["yfinance", "fks_data"], help="Data source")
       parser.add_argument("--max-episodes", type=int, default=1000, help="Maximum training episodes")
       parser.add_argument("--initial-balance", type=float, default=10000.0, help="Initial cash balance")
       parser.add_argument("--transaction-cost", type=float, default=0.001, help="Transaction cost (0.001 = 0.1%%)")
       parser.add_argument("--slippage", type=float, default=0.0005, help="Slippage (0.0005 = 0.05%%)")
       parser.add_argument("--lr", type=float, default=0.001, help="Learning rate")
       parser.add_argument("--gamma", type=float, default=0.99, help="Discount factor")
       parser.add_argument("--epsilon", type=float, default=0.2, help="PPO clipping parameter")
       parser.add_argument("--ppo-epochs", type=int, default=10, help="PPO update epochs")
       parser.add_argument("--batch-size", type=int, default=128, help="Batch size")
       parser.add_argument("--threshold", type=float, default=0.5, help="Early stopping threshold (Sharpe ratio)")
       parser.add_argument("--model-save-path", type=str, default="./models/ppo/trading_ppo.pt", help="Model save path")
       parser.add_argument("--use-mlflow", action="store_true", help="Use MLflow for tracking")
       parser.add_argument("--mlflow-uri", type=str, help="MLflow tracking URI")
       
       args = parser.parse_args()
       
       # Setup MLflow
       if args.use_mlflow:
           if args.mlflow_uri:
               mlflow.set_tracking_uri(args.mlflow_uri)
           mlflow.set_experiment("ppo_trading")
       
       # Split data into train and test
       train_start, train_end, test_start, test_end = split_data_dates(
           args.start_date,
           args.end_date,
           train_ratio=0.8
       )
       
       logger.info(f"Training period: {train_start} to {train_end}")
       logger.info(f"Test period: {test_start} to {test_end}")
       
       # Create training environment
       logger.info(f"Creating training environment for {args.ticker}...")
       train_env = TradingEnv(
           ticker=args.ticker,
           start_date=train_start,
           end_date=train_end,
           initial_balance=args.initial_balance,
           transaction_cost=args.transaction_cost,
           slippage=args.slippage,
           data_source=args.data_source,
           normalize_states=True
       )
       
       # Create test environment
       logger.info(f"Creating test environment for {args.ticker}...")
       test_env = TradingEnv(
           ticker=args.ticker,
           start_date=test_start,
           end_date=test_end,
           initial_balance=args.initial_balance,
           transaction_cost=args.transaction_cost,
           slippage=args.slippage,
           data_source=args.data_source,
           normalize_states=True
       )
       
       # Get feature dimension from environment
       obs_shape = train_env.observation_space.shape
       feature_dim = obs_shape[0] if len(obs_shape) == 1 else obs_shape[0]
       num_actions = 3  # hold, buy, sell
       
       logger.info(f"Feature dimension: {feature_dim}")
       logger.info(f"Action space: {num_actions} (hold, buy, sell)")
       
       # Train PPO agent
       logger.info("Starting PPO training...")
       results = run_ppo_training(
           env_train=train_env,
           env_test=test_env,
           feature_dim=feature_dim,
           num_actions=num_actions,
           max_episodes=args.max_episodes,
           threshold=args.threshold,
           lr=args.lr,
           gamma=args.gamma,
           epsilon=args.epsilon,
           ppo_epochs=args.ppo_epochs,
           batch_size=args.batch_size,
           model_save_path=args.model_save_path,
           use_mlflow=args.use_mlflow
       )
       
       # Final evaluation on test set
       logger.info("Running final evaluation on test set...")
       policy = results["policy"]
       final_reward = evaluate(test_env, policy, n_episodes=10, deterministic=True)
       
       logger.info(f"Final test reward: {final_reward:.4f}")
       logger.info(f"Best test reward: {results['training_stats']['best_test_reward']:.4f}")
       logger.info(f"Model saved to: {results['model_path']}")
       
       # Calculate performance metrics
       test_env.reset()
       episode_rewards = []
       episode_returns = []
       
       for _ in range(10):
           obs, info = test_env.reset()
           done = False
           total_reward = 0.0
           
           while not done:
               obs_t = torch.FloatTensor(obs).unsqueeze(0)
               action, _, _, _ = policy.get_action(obs_t, deterministic=True)
               obs, reward, terminated, truncated, info = test_env.step(action)
               done = terminated or truncated
               total_reward += reward
           
           episode_rewards.append(total_reward)
           final_info = test_env._get_info()
           episode_returns.append(final_info["profit_pct"])
       
       avg_return = np.mean(episode_returns)
       sharpe_ratio = np.mean(episode_returns) / (np.std(episode_returns) + 1e-8) * np.sqrt(252)  # Annualized
       
       logger.info(f"Average return: {avg_return:.2f}%%")
       logger.info(f"Sharpe ratio: {sharpe_ratio:.2f}")
       
       if args.use_mlflow:
           mlflow.log_metrics({
               "final_test_reward": final_reward,
               "avg_return": avg_return,
               "sharpe_ratio": sharpe_ratio
           })
       
       logger.info("Training completed successfully!")
   
   if __name__ == "__main__":
       main()
   ```

**Deliverable**: Complete training script with trading environment integration

**Success Criteria**:
- Training script runs without errors
- Environment loads data correctly
- PPO training completes successfully
- Model saves and loads correctly
- Evaluation metrics calculated (returns, Sharpe ratio)
- MLflow tracking works (if enabled)

**Practical Usage Example**:
```bash
# Train on AAPL using yfinance
python -m training.src.ppo.train_trading_ppo \
    --ticker AAPL \
    --start-date 2020-01-01 \
    --end-date 2025-11-01 \
    --max-episodes 1000 \
    --data-source yfinance \
    --use-mlflow

# Train on BTC using fks_data
python -m training.src.ppo.train_trading_ppo \
    --ticker BTC-USD \
    --start-date 2020-01-01 \
    --end-date 2025-11-01 \
    --max-episodes 1000 \
    --data-source fks_data \
    --transaction-cost 0.002 \
    --use-mlflow
```

**Expected Performance** (based on research):
- **Directional Accuracy**: 50-65% (vs. 58% baseline)
- **Annualized Returns**: 10-30% (backtest, before slippage)
- **Sharpe Ratio**: 0.5-1.5 (risk-adjusted returns)
- **Drawdown**: 10-20% (maximum loss from peak)

**Limitations and Tips**:
- **Overfitting**: PPO may overfit to training data—use train/test splits and early stopping
- **Noisy Markets**: Real markets are noisy—expect lower performance than backtests (10-15% returns)
- **Ensembles**: Combine multiple PPO models for robustness
- **Risk Management**: Always use stop-losses and position sizing in production
- **Start Simple**: Test on CartPole environment first to verify code before trading

---

### Task 1.2: Create Feature Vector Builder

**Objective**: Build 22D feature vector from FKS data sources

**Actions for AI Agent**:

1. **Create feature extractor**:
   ```
   File: repo/training/src/ppo/feature_extractor.py
   Content:
   import numpy as np
   import pandas as pd
   from typing import Dict, Any, List
   from loguru import logger
   import httpx
   
   class FKSFeatureExtractor:
       """Extract 22D feature vector for PPO"""
       
       def __init__(self, data_service_url: str = "http://fks_data:8003"):
           self.data_service_url = data_service_url
       
       async def extract_features(
           self,
           symbol: str,
           timeframe: str = "1h"
       ) -> np.ndarray:
           """Extract 22D feature vector"""
           # Fetch market data
           market_data = await self._fetch_market_data(symbol, timeframe)
           
           if market_data is None or len(market_data) < 100:
               logger.warning(f"Insufficient data for {symbol}")
               return np.zeros(22)
           
           df = pd.DataFrame(market_data)
           
           # Feature 1-4: Price changes (1m, 5m, 15m, 1h)
           features = []
           features.append(self._price_change(df, 1))
           features.append(self._price_change(df, 5))
           features.append(self._price_change(df, 15))
           features.append(self._price_change(df, 60))
           
           # Feature 5-8: Volume changes
           features.append(self._volume_change(df, 1))
           features.append(self._volume_change(df, 5))
           features.append(self._volume_change(df, 15))
           features.append(self._volume_change(df, 60))
           
           # Feature 9-12: Volatility (rolling std)
           features.append(self._volatility(df, 5))
           features.append(self._volatility(df, 15))
           features.append(self._volatility(df, 60))
           features.append(self._volatility(df, 240))
           
           # Feature 13-16: VWAP deviation
           features.append(self._vwap_deviation(df, 5))
           features.append(self._vwap_deviation(df, 15))
           features.append(self._vwap_deviation(df, 60))
           features.append(self._vwap_deviation(df, 240))
           
           # Feature 17-20: Regime indicators
           features.append(self._trend_regime(df))
           features.append(self._volatility_regime(df))
           features.append(self._order_flow_regime(df))
           features.append(self._momentum_regime(df))
           
           # Feature 21-22: Market microstructure
           features.append(self._bid_ask_spread(df))
           features.append(self._liquidity_indicator(df))
           
           feature_vector = np.array(features, dtype=np.float32)
           
           # Normalize features
           feature_vector = (feature_vector - feature_vector.mean()) / (feature_vector.std() + 1e-8)
           
           return feature_vector
       
       async def _fetch_market_data(self, symbol: str, timeframe: str) -> List[Dict]:
           """Fetch market data from fks_data"""
           try:
               async with httpx.AsyncClient() as client:
                   response = await client.get(
                       f"{self.data_service_url}/api/v1/data/{symbol}",
                       params={"interval": timeframe, "limit": 500}
                   )
                   response.raise_for_status()
                   return response.json().get("data", [])
           except Exception as e:
               logger.error(f"Failed to fetch market data: {e}")
               return None
       
       def _price_change(self, df: pd.DataFrame, periods: int) -> float:
           """Calculate price change over periods"""
           if len(df) < periods:
               return 0.0
           return (df["close"].iloc[-1] - df["close"].iloc[-periods]) / df["close"].iloc[-periods]
       
       def _volume_change(self, df: pd.DataFrame, periods: int) -> float:
           """Calculate volume change over periods"""
           if len(df) < periods:
               return 0.0
           return (df["volume"].iloc[-periods:].mean() - df["volume"].iloc[-2*periods:-periods].mean()) / (df["volume"].iloc[-2*periods:-periods].mean() + 1e-8)
       
       def _volatility(self, df: pd.DataFrame, window: int) -> float:
           """Calculate rolling volatility"""
           if len(df) < window:
               return 0.0
           returns = df["close"].pct_change()
           return returns.rolling(window=window).std().iloc[-1]
       
       def _vwap_deviation(self, df: pd.DataFrame, window: int) -> float:
           """Calculate VWAP deviation"""
           if len(df) < window:
               return 0.0
           vwap = (df["close"] * df["volume"]).rolling(window=window).sum() / df["volume"].rolling(window=window).sum()
           return (df["close"].iloc[-1] - vwap.iloc[-1]) / vwap.iloc[-1]
       
       def _trend_regime(self, df: pd.DataFrame) -> float:
           """Detect trend regime (1.0 = strong uptrend, -1.0 = strong downtrend)"""
           if len(df) < 50:
               return 0.0
           ema_fast = df["close"].ewm(span=10).mean()
           ema_slow = df["close"].ewm(span=50).mean()
           return 1.0 if ema_fast.iloc[-1] > ema_slow.iloc[-1] else -1.0
       
       def _volatility_regime(self, df: pd.DataFrame) -> float:
           """Detect volatility regime (1.0 = high, -1.0 = low)"""
           if len(df) < 50:
               return 0.0
           recent_vol = df["close"].pct_change().rolling(20).std().iloc[-1]
           long_vol = df["close"].pct_change().rolling(100).std().iloc[-1]
           return 1.0 if recent_vol > long_vol else -1.0
       
       def _order_flow_regime(self, df: pd.DataFrame) -> float:
           """Detect order flow regime"""
           if len(df) < 20:
               return 0.0
           # Simple heuristic: positive if more buying pressure
           price_change = (df["close"].iloc[-1] - df["close"].iloc[-20]) / df["close"].iloc[-20]
           return np.tanh(price_change * 10)  # Normalize to [-1, 1]
       
       def _momentum_regime(self, df: pd.DataFrame) -> float:
           """Detect momentum regime"""
           if len(df) < 14:
               return 0.0
           # RSI-like momentum
           delta = df["close"].diff()
           gain = (delta.where(delta > 0, 0)).rolling(14).mean()
           loss = (-delta.where(delta < 0, 0)).rolling(14).mean()
           rs = gain / (loss + 1e-8)
           rsi = 100 - (100 / (1 + rs))
           return (rsi.iloc[-1] - 50) / 50  # Normalize to [-1, 1]
       
       def _bid_ask_spread(self, df: pd.DataFrame) -> float:
           """Estimate bid-ask spread"""
           if "high" not in df.columns or "low" not in df.columns:
               return 0.0
           spread = (df["high"] - df["low"]) / df["close"]
           return spread.rolling(20).mean().iloc[-1]
       
       def _liquidity_indicator(self, df: pd.DataFrame) -> float:
           """Calculate liquidity indicator"""
           if "volume" not in df.columns:
               return 0.0
           volume_ma = df["volume"].rolling(20).mean()
           return (df["volume"].iloc[-1] / volume_ma.iloc[-1]) if volume_ma.iloc[-1] > 0 else 0.0
   ```

**Deliverable**: Feature extractor implemented with 22D feature vector

**Success Criteria**: Features extracted correctly, normalized, ready for PPO training

---

### Task 1.3: Create Trading Environment for PPO Training

**Objective**: Build a Gymnasium-compatible trading environment for training PPO agents on stock data with discrete actions (buy/sell/hold)

**Key Concepts**:
- **Trading Environment**: Simulates real trading with historical data
- **State Space**: Price data, technical indicators (RSI, MACD, VWAP)
- **Action Space**: Discrete (0: hold, 1: buy, 2: sell)
- **Reward Function**: Profit minus transaction costs, normalized for stability
- **Transaction Costs**: Realistic fees (0.1-0.2%) and slippage (0.05%)

**Actions for AI Agent**:

1. **Create Trading Environment**:
   ```
   File: repo/training/src/ppo/trading_env.py
   Content:
   import gymnasium as gym
   import numpy as np
   import pandas as pd
   from typing import Dict, Optional, Tuple
   from loguru import logger
   import yfinance as yf
   from ta import add_all_ta_features
   import httpx
   
   class TradingEnv(gym.Env):
       """Gymnasium-compatible trading environment for PPO training
       
       State: OHLCV data + technical indicators
       Actions: 0 (hold), 1 (buy), 2 (sell)
       Reward: Profit minus transaction costs, normalized to [-1, 1]
       """
       
       metadata = {"render_modes": ["human"]}
       
       def __init__(
           self,
           ticker: str = "AAPL",
           start_date: str = "2020-01-01",
           end_date: str = "2025-11-01",
           initial_balance: float = 10000.0,
           transaction_cost: float = 0.001,  # 0.1% transaction cost
           slippage: float = 0.0005,  # 0.05% slippage
           data_source: str = "yfinance",  # "yfinance" or "fks_data"
           data_service_url: str = "http://fks_data:8003",
           normalize_states: bool = True,
           lookback_window: int = 50
       ):
           """Initialize trading environment
           
           Args:
               ticker: Stock ticker symbol (e.g., "AAPL")
               start_date: Start date for historical data
               end_date: End date for historical data
               initial_balance: Starting cash balance
               transaction_cost: Transaction cost as fraction (0.001 = 0.1%)
               slippage: Slippage as fraction (0.0005 = 0.05%)
               data_source: Data source ("yfinance" or "fks_data")
               data_service_url: URL for fks_data service
               normalize_states: Whether to normalize state features
               lookback_window: Number of historical bars to include in state
           """
           super().__init__()
           
           self.ticker = ticker
           self.start_date = start_date
           self.end_date = end_date
           self.initial_balance = initial_balance
           self.transaction_cost = transaction_cost
           self.slippage = slippage
           self.data_source = data_source
           self.data_service_url = data_service_url
           self.normalize_states = normalize_states
           self.lookback_window = lookback_window
           
           # Load and prepare data
           self.data = self._load_data()
           
           if self.data is None or len(self.data) < self.lookback_window + 10:
               raise ValueError(f"Insufficient data for {ticker}")
           
           # Add technical indicators
           self.data = self._add_indicators(self.data)
           
           # Drop NaN rows (from indicator calculations)
           self.data = self.data.dropna()
           
           if len(self.data) < self.lookback_window + 10:
               raise ValueError(f"Insufficient data after adding indicators for {ticker}")
           
           # Define observation space (all features from data)
           n_features = self.data.shape[1]
           self.observation_space = gym.spaces.Box(
               low=-np.inf,
               high=np.inf,
               shape=(n_features,),
               dtype=np.float32
           )
           
           # Define action space (0: hold, 1: buy, 2: sell)
           self.action_space = gym.spaces.Discrete(3)
           
           # Initialize state
           self.reset()
       
       def _load_data(self) -> Optional[pd.DataFrame]:
           """Load historical data from yfinance or fks_data"""
           if self.data_source == "yfinance":
               logger.info(f"Loading data from yfinance for {self.ticker}...")
               try:
                   data = yf.download(
                       self.ticker,
                       start=self.start_date,
                       end=self.end_date,
                       progress=False
                   )
                   if data.empty:
                       logger.error(f"No data retrieved for {self.ticker}")
                       return None
                   return data
               except Exception as e:
                   logger.error(f"Failed to load data from yfinance: {e}")
                   return None
           elif self.data_source == "fks_data":
               logger.info(f"Loading data from fks_data for {self.ticker}...")
               try:
                   # Fetch from fks_data service
                   response = httpx.get(
                       f"{self.data_service_url}/api/v1/data/{self.ticker}",
                       params={
                           "start_date": self.start_date,
                           "end_date": self.end_date,
                           "interval": "1d"
                       },
                       timeout=30.0
                   )
                   response.raise_for_status()
                   data_dict = response.json()
                   
                   # Convert to DataFrame
                   data = pd.DataFrame(data_dict.get("data", []))
                   if data.empty:
                       logger.error(f"No data retrieved from fks_data for {self.ticker}")
                       return None
                   
                   # Rename columns to match yfinance format
                   if "timestamp" in data.columns:
                       data["Date"] = pd.to_datetime(data["timestamp"])
                       data.set_index("Date", inplace=True)
                   if "open" in data.columns:
                       data.rename(columns={
                           "open": "Open",
                           "high": "High",
                           "low": "Low",
                           "close": "Close",
                           "volume": "Volume"
                       }, inplace=True)
                   
                   return data[["Open", "High", "Low", "Close", "Volume"]]
               except Exception as e:
                   logger.error(f"Failed to load data from fks_data: {e}")
                   return None
           else:
               raise ValueError(f"Unknown data source: {self.data_source}")
       
       def _add_indicators(self, data: pd.DataFrame) -> pd.DataFrame:
           """Add technical indicators using ta library"""
           try:
               # Add all technical indicators
               data = add_all_ta_features(
                   data,
                   open="Open",
                   high="High",
                   low="Low",
                   close="Close",
                   volume="Volume"
               )
               logger.info(f"Added technical indicators. Shape: {data.shape}")
               return data
           except Exception as e:
               logger.warning(f"Failed to add some indicators: {e}")
               # Fallback: add basic indicators manually
               data["sma_20"] = data["Close"].rolling(20).mean()
               data["sma_50"] = data["Close"].rolling(50).mean()
               data["rsi"] = self._calculate_rsi(data["Close"], 14)
               return data
       
       def _calculate_rsi(self, prices: pd.Series, window: int = 14) -> pd.Series:
           """Calculate RSI indicator"""
           delta = prices.diff()
           gain = (delta.where(delta > 0, 0)).rolling(window=window).mean()
           loss = (-delta.where(delta < 0, 0)).rolling(window=window).mean()
           rs = gain / (loss + 1e-8)
           rsi = 100 - (100 / (1 + rs))
           return rsi
       
       def reset(self, seed: Optional[int] = None, options: Optional[dict] = None) -> Tuple[np.ndarray, Dict]:
           """Reset environment to initial state"""
           super().reset(seed=seed)
           
           # Start after indicator warm-up period
           self.current_step = self.lookback_window
           
           # Reset trading state
           self.balance = self.initial_balance
           self.shares = 0
           self.net_worth = self.balance
           self.prev_worth = self.initial_balance
           
           # Trading history
           self.trades = []
           self.portfolio_history = [self.net_worth]
           
           # Get initial observation
           observation = self._get_observation()
           info = self._get_info()
           
           return observation, info
       
       def step(self, action: int) -> Tuple[np.ndarray, float, bool, bool, Dict]:
           """Execute one step in the environment
           
           Args:
               action: 0 (hold), 1 (buy), 2 (sell)
           
           Returns:
               observation: Next state observation
               reward: Reward for this step
               terminated: Whether episode is done
               truncated: Whether episode was truncated
               info: Additional information
           """
           # Get current price
           current_price = self.data["Close"].iloc[self.current_step]
           
           # Store previous net worth
           self.prev_worth = self.net_worth
           
           # Execute action
           if action == 1:  # Buy
               self._execute_buy(current_price)
           elif action == 2:  # Sell
               self._execute_sell(current_price)
           # action == 0: Hold (do nothing)
           
           # Update net worth
           self.net_worth = self.balance + self.shares * current_price
           
           # Calculate reward (normalized profit)
           reward = self._calculate_reward()
           
           # Move to next step
           self.current_step += 1
           
           # Update history
           self.portfolio_history.append(self.net_worth)
           
           # Check if done
           terminated = self.current_step >= len(self.data) - 1
           truncated = self.net_worth < self.initial_balance * 0.1  # 90% loss
           
           # Get next observation
           observation = self._get_observation() if not terminated else np.zeros(self.observation_space.shape)
           info = self._get_info()
           
           return observation, reward, terminated, truncated, info
       
       def _execute_buy(self, price: float):
           """Execute buy action"""
           if self.balance > price:
               # Calculate number of shares we can buy (with fees)
               cost_per_share = price * (1 + self.transaction_cost + self.slippage)
               shares_to_buy = int(self.balance / cost_per_share)
               
               if shares_to_buy > 0:
                   cost = shares_to_buy * cost_per_share
                   self.shares += shares_to_buy
                   self.balance -= cost
                   self.trades.append({
                       "step": self.current_step,
                       "action": "buy",
                       "price": price,
                       "shares": shares_to_buy,
                       "cost": cost
                   })
       
       def _execute_sell(self, price: float):
           """Execute sell action"""
           if self.shares > 0:
               # Calculate revenue (with fees)
               revenue_per_share = price * (1 - self.transaction_cost - self.slippage)
               revenue = self.shares * revenue_per_share
               
               self.trades.append({
                   "step": self.current_step,
                   "action": "sell",
                   "price": price,
                   "shares": self.shares,
                   "revenue": revenue
               })
               
               self.balance += revenue
               self.shares = 0
       
       def _calculate_reward(self) -> float:
           """Calculate reward based on profit
           
           Reward is normalized to [-1, 1] for stability:
           - Positive reward for profit
           - Negative reward for loss
           - Clipped to prevent extreme values
           """
           # Calculate profit/loss
           profit = self.net_worth - self.prev_worth
           profit_pct = profit / self.prev_worth if self.prev_worth > 0 else 0.0
           
           # Normalize reward (clip to [-1, 1])
           reward = np.clip(profit_pct * 10, -1.0, 1.0)
           
           return reward
       
       def _get_observation(self) -> np.ndarray:
           """Get current observation (state)"""
           if self.current_step >= len(self.data):
               return np.zeros(self.observation_space.shape)
           
           # Get current row of data (all features)
           obs = self.data.iloc[self.current_step].values.astype(np.float32)
           
           # Normalize if requested
           if self.normalize_states:
               # Simple normalization (can be improved with rolling statistics)
               obs = (obs - obs.mean()) / (obs.std() + 1e-8)
           
           return obs
       
       def _get_info(self) -> Dict:
           """Get additional information about current state"""
           return {
               "balance": self.balance,
               "shares": self.shares,
               "net_worth": self.net_worth,
               "current_step": self.current_step,
               "total_trades": len(self.trades),
               "profit": self.net_worth - self.initial_balance,
               "profit_pct": (self.net_worth - self.initial_balance) / self.initial_balance * 100
           }
       
       def render(self, mode: str = "human"):
           """Render environment (for visualization)"""
           if mode == "human":
               print(f"Step: {self.current_step}")
               print(f"Balance: ${self.balance:.2f}")
               print(f"Shares: {self.shares}")
               print(f"Net Worth: ${self.net_worth:.2f}")
               print(f"Profit: ${self.net_worth - self.initial_balance:.2f}")
   ```

2. **Update requirements.txt**:
   ```
   File: repo/training/requirements.txt
   Add:
   yfinance>=0.2.0
   ta>=0.11.0
   httpx>=0.25.0
   ```

3. **Create Environment Wrapper for Vectorization**:
   ```
   File: repo/training/src/ppo/env_wrapper.py
   Content:
   import numpy as np
   from typing import List
   from stable_baselines3.common.vec_env import SubprocVecEnv, DummyVecEnv
   from .trading_env import TradingEnv
   
   def make_trading_env(
       ticker: str,
       start_date: str,
       end_date: str,
       n_envs: int = 1,
       **env_kwargs
   ):
       """Create vectorized trading environment
       
       Args:
           ticker: Stock ticker symbol
           start_date: Start date for data
           end_date: End date for data
           n_envs: Number of parallel environments
           **env_kwargs: Additional environment arguments
       
       Returns:
           Vectorized environment (SubprocVecEnv or DummyVecEnv)
       """
       def make_env():
           return TradingEnv(
               ticker=ticker,
               start_date=start_date,
               end_date=end_date,
               **env_kwargs
           )
       
       if n_envs == 1:
           return DummyVecEnv([make_env])
       else:
           return SubprocVecEnv([make_env for _ in range(n_envs)])
   ```

**Deliverable**: Trading environment implemented with yfinance and fks_data support

**Success Criteria**:
- Environment loads data correctly (yfinance or fks_data)
- Technical indicators added successfully
- Actions (buy/sell/hold) execute correctly
- Rewards calculated properly (profit minus costs)
- State normalization works
- Environment resets and steps correctly

**Key Features**:
- **Dual Data Sources**: Supports yfinance (for quick testing) and fks_data (for production)
- **Technical Indicators**: Automatic indicator calculation using ta library
- **Realistic Costs**: Transaction costs (0.1%) and slippage (0.05%)
- **State Normalization**: Optional normalization for training stability
- **Reward Clipping**: Rewards normalized to [-1, 1] for stability
- **Vectorization Support**: Ready for parallel environment training

---

## 📋 Phase 2: Reward Engineering (Weeks 2-3)

### Task 2.1: Implement Dual-Head Reward System

**Objective**: Create reward system with directional and auxiliary rewards

**Actions for AI Agent**:

1. **Create reward calculator**:
   ```
   File: repo/training/src/ppo/reward_calculator.py
   Content:
   import numpy as np
   from typing import Dict, Any, Tuple
   from loguru import logger
   
   class DualHeadRewardCalculator:
       """Calculate dual-head rewards for PPO"""
       
       def __init__(
           self,
           directional_weight: float = 0.7,
           auxiliary_weight: float = 0.3,
           volatility_momentum_scale: float = 1.0,
           tiered_suppression: bool = True
       ):
           self.directional_weight = directional_weight
           self.auxiliary_weight = auxiliary_weight
           self.volatility_momentum_scale = volatility_momentum_scale
           self.tiered_suppression = tiered_suppression
       
       def calculate_rewards(
           self,
           predictions: np.ndarray,
           actuals: np.ndarray,
           market_data: Dict[str, Any],
           selected_action: int
       ) -> Tuple[float, float]:
           """Calculate directional and auxiliary rewards"""
           
           # Directional reward (accuracy)
           directional_reward = self._calculate_directional_reward(
               predictions,
               actuals
           )
           
           # Auxiliary reward (costs, volatility, risk)
           auxiliary_reward = self._calculate_auxiliary_reward(
               predictions,
               actuals,
               market_data,
               selected_action
           )
           
           # Scale by volatility momentum
           if self.volatility_momentum_scale > 0:
               volatility = market_data.get("volatility", 1.0)
               volatility_momentum = market_data.get("volatility_momentum", 1.0)
               scale = 1.0 + (volatility_momentum - 1.0) * self.volatility_momentum_scale
               directional_reward *= scale
               auxiliary_reward *= scale
           
           # Tiered suppression for low-confidence predictions
           if self.tiered_suppression:
               confidence = market_data.get("confidence", 0.5)
               if confidence < 0.3:
                   directional_reward *= 0.5
                   auxiliary_reward *= 0.5
               elif confidence < 0.5:
                   directional_reward *= 0.7
                   auxiliary_reward *= 0.7
           
           return directional_reward, auxiliary_reward
       
       def _calculate_directional_reward(
           self,
           predictions: np.ndarray,
           actuals: np.ndarray
       ) -> float:
           """Calculate directional accuracy reward"""
           if len(predictions) == 0 or len(actuals) == 0:
               return 0.0
           
           # Convert to directions
           pred_directions = np.sign(predictions)
           actual_directions = np.sign(actuals)
           
           # Calculate accuracy
           correct = np.sum(pred_directions == actual_directions)
           total = len(predictions)
           accuracy = correct / total if total > 0 else 0.0
           
           # Reward: accuracy - 0.5 (centered at 0)
           reward = (accuracy - 0.5) * 2.0  # Scale to [-1, 1]
           
           return reward
       
       def _calculate_auxiliary_reward(
           self,
           predictions: np.ndarray,
           actuals: np.ndarray,
           market_data: Dict[str, Any],
           selected_action: int
       ) -> float:
           """Calculate auxiliary reward (costs, volatility, risk)"""
           reward = 0.0
           
           # Trading cost penalty
           trading_cost = market_data.get("trading_cost", 0.001)  # 0.1% default
           reward -= trading_cost
           
           # Volatility penalty (higher volatility = higher risk)
           volatility = market_data.get("volatility", 1.0)
           reward -= volatility * 0.1
           
           # Sharpe ratio bonus
           returns = predictions - actuals
           if len(returns) > 1:
               sharpe = np.mean(returns) / (np.std(returns) + 1e-8) * np.sqrt(252)
               reward += sharpe * 0.1
           
           # Drawdown penalty
           cumulative_returns = np.cumsum(returns)
           peak = np.maximum.accumulate(cumulative_returns)
           drawdown = (cumulative_returns - peak) / (peak + 1e-8)
           max_drawdown = np.min(drawdown)
           reward += max_drawdown * 0.2  # Penalize drawdowns
           
           # Action diversity bonus (encourage exploration)
           action_counts = market_data.get("action_counts", {})
           if selected_action in action_counts:
               count = action_counts[selected_action]
               diversity_bonus = 1.0 / (count + 1)  # Less used actions get bonus
               reward += diversity_bonus * 0.05
           
           return reward
       
       def combine_rewards(
           self,
           directional_reward: float,
           auxiliary_reward: float
       ) -> float:
           """Combine directional and auxiliary rewards"""
           total_reward = (
               self.directional_weight * directional_reward +
               self.auxiliary_weight * auxiliary_reward
           )
           
           return total_reward
   ```

**Deliverable**: Dual-head reward system implemented

**Success Criteria**: Rewards calculated correctly, volatility scaling works, tiered suppression applied

---

## 📋 Phase 3: Training Pipeline (Weeks 3-5)

### Task 3.1: Create Training Loop

**Objective**: Implement PPO training loop with fks_data historical data

**Actions for AI Agent**:

1. **Create training script**:
   ```
   File: repo/training/src/ppo/train.py
   Content:
   import asyncio
   import torch
   import numpy as np
   from typing import List, Dict, Any
   from loguru import logger
   from .policy_network import DualHeadPPOPolicy
   from .trainer import PPOTrainer
   from .feature_extractor import FKSFeatureExtractor
   from .reward_calculator import DualHeadRewardCalculator
   import httpx
   import mlflow
   
   class PPOTrainingPipeline:
       """PPO training pipeline for meta-learning"""
       
       def __init__(
           self,
           feature_dim: int = 22,
           num_actions: int = 10,
           data_service_url: str = "http://fks_data:8003"
       ):
           self.trainer = PPOTrainer(feature_dim, num_actions)
           self.feature_extractor = FKSFeatureExtractor(data_service_url)
           self.reward_calculator = DualHeadRewardCalculator()
           self.num_actions = num_actions
       
       async def train(
           self,
           symbol: str,
           start_date: str,
           end_date: str,
           epochs: int = 5,
           episodes: int = 1000,
           batch_size: int = 128
       ):
           """Train PPO on historical data"""
           logger.info(f"Starting PPO training for {symbol}")
           
           # Initialize MLflow
           mlflow.set_experiment("ppo_meta_learning")
           
           with mlflow.start_run():
               # Log hyperparameters
               mlflow.log_params({
                   "symbol": symbol,
                   "feature_dim": 22,
                   "num_actions": self.num_actions,
                   "epochs": epochs,
                   "episodes": episodes,
                   "batch_size": batch_size
               })
               
               # Training loop
               for episode in range(episodes):
                   # Collect episode data
                   states, actions, rewards, log_probs, values = await self._collect_episode(
                       symbol,
                       start_date,
                       end_date
                   )
                   
                   if len(states) == 0:
                       continue
                   
                   # Compute returns and advantages
                   returns = self.trainer.compute_returns(rewards, [False] * len(rewards))
                   advantages = self.trainer.compute_advantages(returns, values)
                   
                   # Update policy
                   self.trainer.update_policy(
                       torch.tensor(states, dtype=torch.float32),
                       torch.tensor(actions, dtype=torch.long),
                       torch.tensor(log_probs, dtype=torch.float32),
                       torch.tensor(advantages, dtype=torch.float32),
                       torch.tensor(returns, dtype=torch.float32),
                       epochs=epochs,
                       batch_size=batch_size
                   )
                   
                   # Log metrics
                   if episode % 10 == 0:
                       avg_reward = np.mean(rewards)
                       avg_return = np.mean(returns)
                       logger.info(f"Episode {episode}: Avg reward = {avg_reward:.4f}, Avg return = {avg_return:.4f}")
                       
                       mlflow.log_metrics({
                           "episode_reward": avg_reward,
                           "episode_return": avg_return,
                           "episode": episode
                       })
               
               # Save model
               model_path = f"models/ppo_{symbol}_{episodes}.pth"
               torch.save(self.trainer.policy.state_dict(), model_path)
               mlflow.log_artifact(model_path)
               
               logger.info(f"Training complete. Model saved to {model_path}")
       
       async def _collect_episode(
           self,
           symbol: str,
           start_date: str,
           end_date: str
       ) -> Tuple[List, List, List, List, List]:
           """Collect one episode of experience"""
           states = []
           actions = []
           rewards = []
           log_probs = []
           values = []
           
           # Fetch historical data
           historical_data = await self._fetch_historical_data(symbol, start_date, end_date)
           
           if historical_data is None or len(historical_data) < 100:
               return states, actions, rewards, log_probs, values
           
           # Process data in windows
           window_size = 100
           for i in range(window_size, len(historical_data)):
               # Extract features
               feature_vector = await self.feature_extractor.extract_features(
                   symbol,
                   historical_data[i-window_size:i]
               )
               
               if feature_vector is None:
                   continue
               
               # Get action from policy
               state_tensor = torch.tensor(feature_vector, dtype=torch.float32).unsqueeze(0)
               action, value, log_prob = self.trainer.policy.get_action(state_tensor)
               
               # Get prediction from selected strategy
               prediction = await self._get_prediction(symbol, action, historical_data[i-window_size:i])
               
               # Calculate reward
               actual = historical_data[i]["close"] - historical_data[i-1]["close"]
               directional_reward, auxiliary_reward = self.reward_calculator.calculate_rewards(
                   np.array([prediction]),
                   np.array([actual]),
                   {"volatility": np.std([d["close"] for d in historical_data[i-10:i]])},
                   action
               )
               total_reward = self.reward_calculator.combine_rewards(directional_reward, auxiliary_reward)
               
               # Store experience
               states.append(feature_vector)
               actions.append(action)
               rewards.append(total_reward)
               log_probs.append(log_prob.item())
               values.append(value)
           
           return states, actions, rewards, log_probs, values
       
       async def _fetch_historical_data(self, symbol: str, start_date: str, end_date: str) -> List[Dict]:
           """Fetch historical data from fks_data"""
           try:
               async with httpx.AsyncClient() as client:
                   response = await client.get(
                       f"http://fks_data:8003/api/v1/data/{symbol}",
                       params={
                           "start_date": start_date,
                           "end_date": end_date,
                           "interval": "1h",
                           "limit": 10000
                       }
                   )
                   response.raise_for_status()
                   return response.json().get("data", [])
           except Exception as e:
               logger.error(f"Failed to fetch historical data: {e}")
               return None
       
       async def _get_prediction(self, symbol: str, action: int, data: List[Dict]) -> float:
           """Get prediction from selected strategy"""
           # Map action to strategy
           strategies = [
               "arima",
               "var",
               "garch",
               "bayesian_regression",
               "random_forest",
               "xgboost",
               "lightgbm",
               "lstm",
               "cnn1d",
               "wavenet"
           ]
           
           if action >= len(strategies):
               return 0.0
           
           strategy = strategies[action]
           
           # Call fks_app to get prediction
           try:
               async with httpx.AsyncClient() as client:
                   response = await client.post(
                       f"http://fks_app:8002/api/strategies/{strategy}/predict",
                       json={"symbol": symbol, "data": data}
                   )
                   response.raise_for_status()
                   result = response.json()
                   return result.get("prediction", 0.0)
           except Exception as e:
               logger.error(f"Failed to get prediction from {strategy}: {e}")
               return 0.0
   ```

**Deliverable**: PPO training pipeline implemented

**Success Criteria**: Training loop runs, experiences collected, policy updates, MLflow logging works

---

## 📋 Phase 4: Hybrid PPO-LangGraph Integration (Weeks 5-6)

### Task 4.1: Integrate PPO with LangGraph Multi-Agent System

**Objective**: Use PPO to optimize routing in LangGraph multi-agent debates

**Actions for AI Agent**:

1. **Create PPO router node**:
   ```
   File: repo/ai/src/agents/ppo_router.py
   Content:
   from typing import Dict, Any
   import torch
   from loguru import logger
   import httpx
   
   class PPORouter:
       """PPO-based router for LangGraph multi-agent system"""
       
       def __init__(self, model_path: str):
           # Load PPO policy
           from repo.training.src.ppo.policy_network import DualHeadPPOPolicy
           
           self.policy = DualHeadPPOPolicy(feature_dim=22, num_actions=3)  # 3 agents: stock, forex, crypto
           self.policy.load_state_dict(torch.load(model_path))
           self.policy.eval()
           
           self.feature_extractor = None  # Will be set from fks_training
       
       async def route(
           self,
           state: Dict[str, Any],
           feature_vector: torch.Tensor
       ) -> str:
           """Route to appropriate agent using PPO policy"""
           # Get action from policy
           with torch.no_grad():
               action_probs, _ = self.policy(feature_vector.unsqueeze(0))
               action = torch.argmax(action_probs, dim=-1).item()
           
           # Map action to agent
           agents = ["stock", "forex", "crypto"]
           selected_agent = agents[action]
           
           logger.info(f"PPO routed to {selected_agent} agent (action: {action}, prob: {action_probs[0][action]:.4f})")
           
           return selected_agent
       
       async def update_with_feedback(
           self,
           state: Dict[str, Any],
           selected_agent: str,
           reward: float
       ):
           """Update PPO policy with feedback (online learning)"""
           # This would integrate with PPO trainer for online updates
           # For now, just log the feedback
           logger.info(f"PPO feedback: agent={selected_agent}, reward={reward:.4f}")
   ```

2. **Integrate into LangGraph workflow**:
   ```
   File: repo/ai/src/graph/ppo_enhanced_graph.py
   Content:
   from langgraph.graph import StateGraph, END
   from typing import TypedDict, Dict, Any
   from ..agents.ppo_router import PPORouter
   from ..agents.stockbot import StockBot
   from ..agents.forexbot import ForexBot
   from ..agents.cryptobot import CryptoBot
   from loguru import logger
   import torch
   
   class AgentState(TypedDict):
       symbol: str
       market_data: Dict[str, Any]
       feature_vector: torch.Tensor
       selected_agent: str
       signal: Dict[str, Any]
       reward: float
   
   class PPOEnhancedWorkflow:
       """LangGraph workflow with PPO routing"""
       
       def __init__(self, ppo_model_path: str):
           self.ppo_router = PPORouter(ppo_model_path)
           self.stockbot = StockBot()
           self.forexbot = ForexBot()
           self.cryptobot = CryptoBot()
           self.workflow = self._build_workflow()
       
       def _build_workflow(self) -> StateGraph:
           """Build LangGraph workflow with PPO routing"""
           workflow = StateGraph(AgentState)
           
           # Add nodes
           workflow.add_node("extract_features", self._extract_features)
           workflow.add_node("ppo_route", self._ppo_route)
           workflow.add_node("stock_analyze", self._stock_analyze)
           workflow.add_node("forex_analyze", self._forex_analyze)
           workflow.add_node("crypto_analyze", self._crypto_analyze)
           workflow.add_node("calculate_reward", self._calculate_reward)
           
           # Define edges
           workflow.set_entry_point("extract_features")
           workflow.add_edge("extract_features", "ppo_route")
           workflow.add_conditional_edges(
               "ppo_route",
               self._route_to_agent,
               {
                   "stock": "stock_analyze",
                   "forex": "forex_analyze",
                   "crypto": "crypto_analyze"
               }
           )
           workflow.add_edge("stock_analyze", "calculate_reward")
           workflow.add_edge("forex_analyze", "calculate_reward")
           workflow.add_edge("crypto_analyze", "calculate_reward")
           workflow.add_edge("calculate_reward", END)
           
           return workflow.compile()
       
       async def _extract_features(self, state: AgentState) -> AgentState:
           """Extract features for PPO"""
           # This would call fks_training feature extractor
           # For now, use placeholder
           feature_vector = torch.randn(22)  # Placeholder
           state["feature_vector"] = feature_vector
           return state
       
       async def _ppo_route(self, state: AgentState) -> AgentState:
           """Route using PPO"""
           selected_agent = await self.ppo_router.route(
               state,
               state["feature_vector"]
           )
           state["selected_agent"] = selected_agent
           return state
       
       def _route_to_agent(self, state: AgentState) -> str:
           """Route to selected agent"""
           return state["selected_agent"]
       
       async def _stock_analyze(self, state: AgentState) -> AgentState:
           """Stock bot analysis"""
           signal = await self.stockbot.analyze(state["symbol"], state["market_data"])
           state["signal"] = signal
           return state
       
       async def _forex_analyze(self, state: AgentState) -> AgentState:
           """Forex bot analysis"""
           signal = await self.forexbot.analyze(state["symbol"], state["market_data"])
           state["signal"] = signal
           return state
       
       async def _crypto_analyze(self, state: AgentState) -> AgentState:
           """Crypto bot analysis"""
           signal = await self.cryptobot.analyze(state["symbol"], state["market_data"])
           state["signal"] = signal
           return state
       
       async def _calculate_reward(self, state: AgentState) -> AgentState:
           """Calculate reward for PPO update"""
           # This would calculate reward based on signal quality
           reward = 0.5  # Placeholder
           state["reward"] = reward
           
           # Update PPO with feedback
           await self.ppo_router.update_with_feedback(
               state,
               state["selected_agent"],
               reward
           )
           
           return state
       
       async def run(self, symbol: str, market_data: Dict[str, Any]) -> Dict[str, Any]:
           """Run PPO-enhanced workflow"""
           initial_state: AgentState = {
               "symbol": symbol,
               "market_data": market_data,
               "feature_vector": torch.randn(22),
               "selected_agent": "",
               "signal": {},
               "reward": 0.0
           }
           
           result = await self.workflow.ainvoke(initial_state)
           return result.get("signal", {})
   ```

**Deliverable**: PPO integrated with LangGraph multi-agent system

**Success Criteria**: PPO routes to appropriate agents, rewards calculated, policy updates with feedback

---

## 📋 Phase 5: Evaluation and Deployment (Weeks 6-8)

### Task 5.1: Create Evaluation Framework

**Objective**: Evaluate PPO performance and compare with baseline

**Actions for AI Agent**:

1. **Create evaluation script**:
   ```
   File: repo/training/src/ppo/evaluate.py
   Content:
   import asyncio
   import torch
   import numpy as np
   from typing import List, Dict, Any
   from loguru import logger
   from .policy_network import DualHeadPPOPolicy
   from .feature_extractor import FKSFeatureExtractor
   import httpx
   
   class PPOEvaluator:
       """Evaluate PPO performance"""
       
       def __init__(self, model_path: str):
           self.policy = DualHeadPPOPolicy(feature_dim=22, num_actions=10)
           self.policy.load_state_dict(torch.load(model_path))
           self.policy.eval()
           
           self.feature_extractor = FKSFeatureExtractor()
       
       async def evaluate(
           self,
           symbol: str,
           test_data: List[Dict]
       ) -> Dict[str, float]:
           """Evaluate PPO on test data"""
           predictions = []
           actuals = []
           actions = []
           
           for i in range(100, len(test_data)):
               # Extract features
               feature_vector = await self.feature_extractor.extract_features(
                   symbol,
                   test_data[i-100:i]
               )
               
               if feature_vector is None:
                   continue
               
               # Get action from policy
               state_tensor = torch.tensor(feature_vector, dtype=torch.float32).unsqueeze(0)
               with torch.no_grad():
                   action_probs, _ = self.policy(state_tensor)
                   action = torch.argmax(action_probs, dim=-1).item()
               
               # Get prediction
               prediction = await self._get_prediction(symbol, action, test_data[i-100:i])
               actual = test_data[i]["close"] - test_data[i-1]["close"]
               
               predictions.append(prediction)
               actuals.append(actual)
               actions.append(action)
           
           # Calculate metrics
           directional_accuracy = self._calculate_directional_accuracy(predictions, actuals)
           mse = np.mean((np.array(predictions) - np.array(actuals)) ** 2)
           r2 = self._calculate_r2(predictions, actuals)
           
           # Action distribution
           action_counts = {}
           for action in actions:
               action_counts[action] = action_counts.get(action, 0) + 1
           
           results = {
               "directional_accuracy": directional_accuracy,
               "mse": mse,
               "r2": r2,
               "action_distribution": action_counts,
               "num_predictions": len(predictions)
           }
           
           logger.info(f"Evaluation results: {results}")
           return results
       
       def _calculate_directional_accuracy(self, predictions: List[float], actuals: List[float]) -> float:
           """Calculate directional accuracy"""
           if len(predictions) == 0 or len(actuals) == 0:
               return 0.0
           
           pred_directions = np.sign(predictions)
           actual_directions = np.sign(actuals)
           
           correct = np.sum(pred_directions == actual_directions)
           return correct / len(predictions)
       
       def _calculate_r2(self, predictions: List[float], actuals: List[float]) -> float:
           """Calculate R² score"""
           if len(predictions) == 0 or len(actuals) == 0:
               return 0.0
           
           ss_res = np.sum((np.array(actuals) - np.array(predictions)) ** 2)
           ss_tot = np.sum((np.array(actuals) - np.mean(actuals)) ** 2)
           
           return 1 - (ss_res / (ss_tot + 1e-8))
       
       async def _get_prediction(self, symbol: str, action: int, data: List[Dict]) -> float:
           """Get prediction from selected strategy"""
           # Same as in training pipeline
           strategies = [
               "arima", "var", "garch", "bayesian_regression",
               "random_forest", "xgboost", "lightgbm", "lstm", "cnn1d", "wavenet"
           ]
           
           if action >= len(strategies):
               return 0.0
           
           strategy = strategies[action]
           
           try:
               async with httpx.AsyncClient() as client:
                   response = await client.post(
                       f"http://fks_app:8002/api/strategies/{strategy}/predict",
                       json={"symbol": symbol, "data": data}
                   )
                   response.raise_for_status()
                   return response.json().get("prediction", 0.0)
           except Exception as e:
               logger.error(f"Failed to get prediction: {e}")
               return 0.0
   ```

**Deliverable**: Evaluation framework implemented

**Success Criteria**: Metrics calculated, directional accuracy >65%, R² >0.9, action distribution analyzed

---

## 📊 Success Metrics

### Performance Targets
- Directional accuracy: >65% (vs. 58% baseline) ✅
- Signal accuracy improvement: 15-25% ✅
- R² score: >0.9 ✅
- Adaptive selection: Regime-aware ✅
- Integration: PPO-LangGraph working ✅

### Business Metrics
- Training time: <24 hours for 1000 episodes ✅
- Inference latency: <10ms per prediction ✅
- Model size: <10MB ✅
- Resilience: Tested with chaos engineering ✅

---

## 🎯 Implementation Checklist

### Phase 1: PPO Architecture ✅
- [ ] Dual-head PPO policy implemented
- [ ] PPO trainer implemented
- [ ] Feature extractor with 22D vector
- [ ] Policy network trains correctly

### Phase 2: Reward Engineering ✅
- [ ] Dual-head reward system implemented
- [ ] Volatility scaling working
- [ ] Tiered suppression applied
- [ ] Rewards calculated correctly

### Phase 3: Training Pipeline ✅
- [ ] Training loop implemented
- [ ] Historical data integration
- [ ] MLflow logging working
- [ ] Policy updates correctly

### Phase 4: Hybrid PPO-LangGraph ✅
- [ ] PPO router integrated
- [ ] LangGraph workflow enhanced
- [ ] Routing works correctly
- [ ] Feedback loop implemented

### Phase 5: Evaluation ✅
- [ ] Evaluation framework implemented
- [ ] Metrics calculated
- [ ] Baseline comparison done
- [ ] Deployment ready

---

**This document provides complete, step-by-step instructions for AI agents to implement PPO meta-learning in FKS. Follow tasks sequentially, ensuring all deliverables are created and success criteria are met.**

