# Ephemeral GitHub Actions Runner on ECS Fargate

This runner registers to your repo on startup, executes one job, then unregisters and exits. Use ECS RunTask to spin it up on demand.

## Build and Push to ECR

```bash
aws ecr create-repository --repository-name github-runner || true
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

docker build -t github-runner infra/github-runner

docker tag github-runner:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/github-runner:latest
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/github-runner:latest
```

## Task Definition

Edit `infra/github-runner/task-def.json` and replace `<ACCOUNT_ID>` and `<REGION>`. Set env vars:
- `GH_OWNER`: your GitHub username or org
- `GH_REPO`: repository name
- `GH_PAT`: PAT with repo and admin:org (if org) scopes

Register the task definition:
```bash
aws ecs register-task-definition --cli-input-json file://infra/github-runner/task-def.json
```

## Run Task on Demand

```bash
aws ecs run-task \
  --cluster <your-cluster> \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<subnet-id>],assignPublicIp=ENABLED}" \
  --task-definition github-runner-task
```

The container will fetch a registration token, register itself as a runner, pick up a job if queued, and unregister on exit.

## Notes
- Ensure `ecsTaskExecutionRole` exists with ECR pull permissions and CloudWatch logs.
- Consider passing `GH_*` via AWS Secrets Manager and task definition `secrets` instead of plain env.
- Pin the runner version as needed (see Dockerfile).


