# GCP Passthrough Internal Load Balancer (ILB) Module

This Terraform module provisions a Google Cloud Platform (GCP) Regional Passthrough Internal Load Balancer (Internal TCP/UDP Load Balancer). It includes the necessary health check, regional backend service, and forwarding rule.

## Features

*   Supports TCP and UDP protocols.
*   Configurable health checks.
*   Supports existing Instance Groups as backends.
*   Option to allocate a static internal IP address.
*   Customizable port range for the frontend.

