# infrastructure-platform-devops

The purpose of this project is to demonstrate key ideas, technologies, methods and principles that a Senoir or Principal DevOps Engineer will be aware of and capable of operating with.

Specifically, it will demonstrate all core aspects of a well developed, performant and feature-rich DevOps and Developer Platform that a conventonal DevOps/SRE/Infrastructuer/Cloud team would have in is remit. Therefore, it will contain functionaity for and examples of CI/CD pipelines, GitOps, IaC, CaC, container runtime, container orchestration, service mesh, monitoring and alerting, FinOps for cloud cose monitoring and optimisation, artifact repository and container repositories. 

These capabilities will reflect the underlying principles and objects that that a this team would be responsible for achieving including Developer Experience, Security and System Reliability. 

It will also demonstrate and adhere to general software principles, best practices and objectives including code quality, maintainability, test coverage, planning and collaboration. In doing so it will also demonatrate shared objectives between Application teams and DevOps/Platform teams.

I hope that others including IT students and professionals may find this resource useful for their own learning and development and I would appreciate any feedback.

Within each DevOps/SRE/Platform category the following technologies will be used:

1. CI/CD Pipeline
    * Buildkite
2. GitOps mechanisms
    * ArgoCD
    * GitHub Actions
    * Trunk vs. Branch vs. Hybrid deployment mechanisms
3. IaC
    * Terraform
    * Drift Detection with Terraform
4. CaC
    * Kubernetes in AWS EKS
    * Helm
    * CloudFormation (maybe)
5. Container Runtime
    * Docker
    * ECS (maybe)
6. Service Mesh
    * Istio
    * Other?
7. Monitoring & Alerting
    * CloudWatch
    * CloudTrail
    * Graphana and Promethius? (likely)
    * ELK Stack? (maybe)
    * Datadog? (maybe)
    * Other?
8. FinOps Monitoring
    * AWS Suite (which ones?)
    * Other monitoring tools?
9. Artifact Repositories
    * Nexus Repository Manager
10. Container Repositories
    * ECR
    * Others?
11. Resource Optimisation and Autoscaling
    * Vertically
    * Horizontally
    * Others?
12. Deployment Strategies
    * Rolling Updates - Kubernetes Native
    * Blue-Green - Istio vs. Argo Rollouts
    * Canary - Istio vs. Argo Rollouts
13. Upgrade Management 
    * Optimising using Helm Charts
    * How else?
14. Testing
    * Unit tests - what tool?
    * Integration tests - what tool?
    * Load tests - what tool?
15. Developer Platform
    * Standardised Resource Procurement and Policies
    * Internal Developer Platform
        * Register for Application, API and Resource Registry
        * Testing Artifacts
        * Repository Compliance
        * Test collections for applications
    * Documentation standards and compliance monitoring
        * Advice and examples
        * Enforcement mechanisms at repository level
16. AuthN, AuthZ, RBAC
    * Application Level - Istio, In-application best practices
        * OAuth 2.0
        * Others?
    * Resource Level
        * Istio
        * K8s
        * AWS-native
        * Others?
    * Secrets and Secret Management
        * Kubernetes-native
        * Istio
        * AWS-services
        * Others?
17. Networking and Security
    * DNS Service - AWS Route53
    * LBs - AWS ALBs & Target Groups
    * Security Groups - AWS-native, Istio Sidecars
    * Virtual Networks - AWS VPC, AWS VPC Subnets
    * Internet Gateway - AWS NAT Gateway
    * WAF - ?
    * Threat Detection and Incident Response - ?
18. In-cluster Security
    * Kubernetes kube-proxies
    * Istio sidecars
19. Application and API Security
    * Programming principles
20. Vulnerability Scanning and Management
    * For Code, Dependencies
        * Pipeline integration - e.g. OWASP ZAP or Snyk
    * For Containers
        * Deployment, operations and cadence with what tool?
21. Code Quality Scanning and Management
    * Pipeline integration - e.g. SonarQube

To demonstrate these items with relevant examples, the following artifacts and technologies will be used:

1. Storage
    1. Databases
        1. Relational Database
            * PostgreSQL or MySQL
        2. Non-relational Databases
            * MongoDB - AWS DynamoDB
    2. Object Storage - AWS S3
    3. Block Storage - AWS EBS Volumes
    4. Caching - Redis
2. Applications
    1. APIs
    2. Microservices
3. Message Queues - Apache Kafka
