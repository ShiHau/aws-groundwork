# Groundwork - the beginning of my AWS practical journey

## 0. Introduction

**Primary focus**: AWS networking, IAM, Terraform, CI/CD, security, observability, and systematic troubleshooting.

Groundwork is a self-directed project focused on developing practical AWS engineering skills through the design, implementation, and operation of a secure cloud application.

Rather than following a prescriptive tutorial, the project starts with explicit requirements and constraints. The architecture, infrastructure, security controls, and deployment workflows are implemented and evaluated against those requirements, with an emphasis on understanding the reasoning behind engineering decisions.

The goal is not to build the largest possible system, but to build a small, reproducible system that demonstrates sound engineering practices and provides opportunities to investigate real-world failure modes.

### Current project status

Phase 1 infrastructure and application implementation is complete. The Terraform-managed backend and static frontend have been deployed, the browser-to-CloudFront-to-API flow has been tested, and CloudWatch logging has been checked. The current local deployment workflow works. Remote Terraform state and GitHub Actions deployment automation are planned for Phase 2; asynchronous processing and email are planned for Phase 3.

## 1. Objective

Build an AWS application that emphasizes practical understanding of core AWS fundamentals, secure architecture, and automated infrastructure management.

### Learning objectives

- **Networking:** Understand VPCs, subnets, route tables, security groups, private connectivity, and VPC endpoints.
- **Security:** Apply least-privilege IAM, IAM database authentication, TLS, encryption at rest, and resource-level access controls.
- **Architecture:** Design a small application using appropriate AWS managed services and understand the trade-offs between alternative designs.
- **Infrastructure as Code:** Use Terraform to provision, update, and destroy infrastructure reproducibly.
- **CI/CD:** Use GitHub Actions to validate code, run tests, and deploy infrastructure and application changes automatically.
- **Observability:** Use CloudWatch and CloudTrail to investigate application behavior, errors, and infrastructure changes.
- **Python and AWS SDK:** Build a simple Python application that uses boto3 to interact with AWS services.

### Constraints

- Minimize AWS costs and use available credits where applicable.
- Keep application logic simple; the primary focus is AWS engineering rather than application development.
- Assume familiarity with Python, Linux, and the theoretical concepts covered by AWS Solutions Architect Associate.
- Prioritize hands-on implementation, troubleshooting, and understanding over the number of services deployed.

The architecture should follow production-oriented practices while remaining appropriately scoped for a single-account, time-limited learning project.

---

## 2. Application Overview

Build a simple web application that accepts user submissions, stores them in a relational database, and sends confirmation emails.

### User workflow

1. A user opens a static website containing a submission form.
2. The user enters a small set of details, including an email address.
3. The frontend submits the request to an HTTPS API.
4. A Python Lambda function validates the request and generates additional application data.
5. The application stores the submission in PostgreSQL on Amazon RDS.
6. The application sends a confirmation email through Amazon SES.
7. The application produces structured logs and metrics that support troubleshooting and operational visibility.
8. In Phase 3, the request processing is extended to asynchronous messaging and confirmation email.

The initial implementation uses synchronous processing. It will be extended to asynchronous processing in Phase 3.

---

## 3. Architecture and Components

### 3.1 Frontend and API

**Amazon S3 + Amazon CloudFront**

- Host the static HTML, CSS, and JavaScript frontend.
- Keep the S3 bucket private and enable S3 Block Public Access.
- Use CloudFront with Origin Access Control to access the S3 bucket.
- Serve the website over HTTPS.

**Amazon API Gateway + AWS Lambda**

- Expose an HTTPS API for form submissions.
- Use a Python Lambda function for input validation and application logic.
- Integrate API Gateway with Lambda.
- Configure CORS to allow requests from the intended frontend origin.
- Return appropriate HTTP status codes and avoid exposing internal errors to clients.

### 3.2 Database

**Amazon RDS for PostgreSQL**

- Store user submissions and associated application data.
- Disable public accessibility and place the database in private subnets.
- Restrict database access through security groups.
- Enable encryption at rest.
- Require TLS for database connections and verify the database server certificate.

**IAM database authentication**

- Enable IAM database authentication for RDS.
- Use a dedicated PostgreSQL application user with minimal database privileges.
- Allow the Lambda execution role to connect using a narrowly scoped `rds-db:connect` permission.
- Generate short-lived database authentication tokens using boto3.
- Do not store database passwords in application configuration or Secrets Manager.
- Use parameterized SQL and sensible connection and query timeouts.

### 3.3 Networking

**Amazon VPC**

- Create the VPC, subnets, route tables, and security groups using Terraform.
- Place RDS in private subnets.
- Attach the application Lambda to the VPC to provide private connectivity to RDS.
- Restrict inbound and outbound traffic to the requirements of the application.
- Document the routing and security boundaries.

**VPC endpoints**

- Introduce interface VPC endpoints when required for private connectivity to AWS services.
- Evaluate a Secrets Manager interface endpoint only if Secrets Manager is introduced for another legitimate use.
- Add other endpoints according to actual service communication requirements.

### 3.4 Email

**Amazon SES**

- Send confirmation emails to users.
- Verify the sender identity and investigate SES sandbox restrictions early.
- Use a dedicated IAM policy for the required SES actions.
- Keep email delivery separate from database permissions.
- Log delivery attempts and failures without unnecessarily exposing personal information.

Full SES integration is part of Phase 3.

### 3.5 Asynchronous messaging

**Amazon SNS + Amazon SQS**

Introduce asynchronous processing in Phase 3.

Target workflow:

1. API Gateway invokes an ingestion Lambda.
2. The ingestion Lambda validates the submission and publishes an event to an SNS topic.
3. SNS fans the event out to two SQS queues.
4. A persistence worker consumes one queue and stores the submission in RDS.
5. A notification worker consumes the other queue and sends an email through SES.

The implementation should cover:

- Queue and subscription policies.
- Independent processing responsibilities.
- Retry behavior and dead-letter queues.
- Queue visibility timeouts and Lambda timeout coordination.
- Idempotency and duplicate event handling.
- Correlation IDs for tracing submissions across services.

### 3.6 Identity and access management

**AWS IAM**

- Apply least-privilege policies to all applicable service identities.
- Use separate roles for application execution, background workers, and infrastructure deployment where appropriate.
- Use resource policies and network controls where supported and required.
- Avoid long-lived AWS credentials in GitHub Actions; Phase 2 uses OIDC federation to assume a restricted AWS deployment role.
- Scope database authentication permissions to the intended RDS resource and database user.

### 3.7 Encryption

- Require HTTPS for public application endpoints.
- Use TLS for database connections with certificate verification.
- Enable encryption at rest for persistent data.
- Document encryption settings for S3, RDS, and SQS where applicable.
- Use AWS-managed encryption keys by default unless customer-managed KMS keys provide a specific learning benefit.

### 3.8 Infrastructure as Code

**Terraform**

- Provision and manage all application infrastructure through Terraform.
- Avoid manual console configuration of application resources.
- Use local Terraform state for the Phase 1 learning workflow.
- Move to a separately provisioned S3 backend with versioning, restricted access, and native S3 state locking (`use_lockfile`) as part of Phase 2.
- Document initial backend setup, deployment, updates, and teardown.

### 3.9 CI/CD

**GitHub Actions**

Phase 2 automates the currently working local deployment workflow with GitHub Actions. Implement:

**Pull request validation**

- Python linting and automated tests.
- Terraform formatting and validation.
- Terraform plan.
- Appropriate security and configuration checks.

**Deployment**

- Authenticate to AWS through OIDC.
- Deploy infrastructure and application changes.
- Run a smoke test against the deployed application.
- Ensure failed validation prevents deployment.

**Teardown**

- Require manual initiation and deliberate confirmation.
- Destroy only the intended application environment.
- Preserve the Terraform backend.
- Verify cleanup and check for retained resources that may continue to incur charges.

### 3.10 Observability

**Amazon CloudWatch**

- Capture structured application logs.
- Record relevant processing stages and correlation IDs.
- Monitor Lambda invocations, errors, duration, and throttling.
- Inspect relevant queue metrics in Phase 3.
- Avoid logging credentials, authentication tokens, or unnecessary personal information.

**AWS CloudTrail**

- Inspect relevant AWS API activity and infrastructure changes.
- Identify which principals performed relevant actions.
- Understand the difference between application logs and AWS API audit events.

---

## 4. Implementation Timeline

### Phase 1 — Core application and infrastructure (implementation complete)

Scope:

- Static frontend using S3 and CloudFront.
- API Gateway and Python Lambda.
- PostgreSQL on private RDS.
- IAM database authentication.
- VPC, subnets, route tables, security groups.
- IAM least privilege and encryption.
- Terraform-managed infrastructure and application code.
- A local deployment workflow that builds Lambda packages, applies Terraform, configures the frontend API URL, uploads website files, and invalidates CloudFront.
- CloudWatch logs and metrics.
- CloudTrail investigation of relevant AWS activity.
- Synchronous database writes.
- End-to-end browser-to-API-to-database testing.

Completion gate:

- The application works from browser to database.
- Infrastructure can be provisioned reproducibly through Terraform.
- The local deployment workflow is tested.
- Networking, IAM, database authentication, and logging can be explained and tested.

### Phase 2 — GitHub Actions deployment automation

Scope:

- Provision and configure the Terraform S3 backend separately, including versioning, restricted access, and native S3 state locking.
- Add GitHub Actions workflows for pull-request validation, Terraform plan, deployment, smoke testing, and deliberate teardown.
- Authenticate to AWS from GitHub Actions using OIDC; do not store long-lived AWS credentials.
- Automate Lambda package builds, frontend API configuration, S3 uploads, and CloudFront invalidations.
- Ensure failed validation blocks deployment and teardown preserves the Terraform backend.

Completion gate:

- Pull requests run the required code and Terraform checks.
- Deployment runs end to end using OIDC and no stored AWS access keys.
- The deployed application passes an automated smoke test.
- Teardown is deliberate, repeatable, and preserves the Terraform backend.

### Phase 3 — Asynchronous processing and email

Scope:

- SNS topic and SQS queue subscriptions.
- Separate persistence and notification workers.
- Asynchronous database processing.
- SES confirmation emails.
- Retry handling, dead-letter queues, and idempotency.
- Correlation IDs and cross-service troubleshooting.
- Updated IAM policies, networking, monitoring, and GitHub Actions deployment workflows.

Completion gate:

- A submission produces an event that reaches both independent consumers.
- Persistence and notification work independently.
- Failure and retry behavior can be demonstrated.
- Duplicate events are handled safely.
- Email delivery is tested subject to SES account restrictions.
- The processing flow can be traced through application logs.

---

## 5. Out of Scope

The following are explicitly excluded from the initial project:

- Disaster recovery and formal recovery-time objectives.
- Complex data pipelines.
- Multi-account architecture.
- Route 53 and custom DNS.
- Separate development, staging, and production environments.
- A custom domain and custom ACM certificate management.
- High-availability architecture beyond the chosen learning configuration.
- Comprehensive production alerting and incident-response processes.
- Production-scale performance optimization.

---

## 6. Success Criteria

The project is successful when the following outcomes are achieved.

### Application functionality

- The static website is accessible over HTTPS.
- Users can submit valid data through the API.
- Valid records are stored correctly in PostgreSQL.
- Invalid requests are rejected safely.
- Phase 1 provides synchronous persistence through the deployed browser/API/database path.
- Phase 2 automates validation and deployment through GitHub Actions and OIDC.
- Phase 3 adds asynchronous persistence and email notification.

### AWS fundamentals

- The VPC, routing, security groups, and endpoint configuration can be explained.
- The distinction between network access, IAM authorization, database authentication, and database privileges is understood.
- IAM database authentication works without storing database passwords.
- Encryption and access controls have been verified rather than merely declared in Terraform.

### Infrastructure and deployment

- Application infrastructure is managed through Terraform.
- Shared remote state and locking work correctly after Phase 2.
- GitHub Actions performs validation and deployment through OIDC.
- Failed checks block deployment.
- Teardown is deliberate, repeatable, and does not destroy the Terraform backend.

### Operations and troubleshooting

- Application behavior can be investigated using CloudWatch.
- Relevant AWS API activity can be inspected through CloudTrail.
- At least two deliberately introduced failures can be diagnosed and corrected.
- The environment can be recreated from a clean state without relying on undocumented manual changes.

### Documentation and engineering judgment

- The repository contains setup, deployment, testing, and teardown instructions.
- Architecture diagrams and key design decisions are documented.
- Cost risks and cleanup requirements are understood.
- Known production omissions and possible future improvements are documented.
- The reasoning behind major service choices and architectural trade-offs can be explained.

---

## 7. Known Production Omissions

- No multi-account isolation.
- No formal disaster recovery.
- Limited high availability.
- No separate deployment environments.
- Limited alerting and incident response.
- No production-scale capacity or performance validation.
- Limited protection against abuse beyond the controls implemented.
- No formal compliance assessment.
- No comprehensive backup restoration exercise.

The priority is to develop practical competence in AWS networking, IAM, Terraform, CI/CD, security, observability, and troubleshooting. The number of deployed services is secondary to the ability to explain, reproduce, operate, and improve the architecture.

## 8. Local deployment workflow

Run `./deploy.sh` from the repository root to build the Lambda packages, initialize and apply Terraform, generate the frontend API configuration from the Terraform `api_url` output, upload the static files to the private S3 bucket, and invalidate the CloudFront cache.

Locally, Terraform prompts for approval before applying infrastructure changes. In CI, set `CI=true` to enable non-interactive Terraform apply; CI should authenticate to AWS through OIDC rather than long-lived access keys.

The generated `config.js` is written to a temporary staging directory and is not committed to source control. The Terraform root derives API Gateway CORS origins from the CloudFront domain output. The deploy identity needs permissions to manage the Terraform resources, upload/delete S3 objects, and create CloudFront invalidations.
