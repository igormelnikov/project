# CI/CD system for OTUS DevOps

A CI/CD system for a sample microservices application developed over the course of studies at OTUS using Terraform, Ansible and Docker.

The application used: a simple search engine by Express 42.
https://github.com/express42/search_engine_ui
https://github.com/express42/search_engine_crawler

Default web page used for tests: https://vitkhab.github.io/search_engine_test_site/

## Getting Started
These instructions describe installation and deployment of the Gitlab CI system to Google Cloud Environment.
The system is then used to manage the microservice repositories, the Docker registry, the CI/CD pipelines and the environments for deploying the app.
### Prerequisites

- Ansible;
- Terraform;
- An SSH key pair which is used for accessing GCE instances for configuration management (`appuser`, `appuser.pub`).
- A GCE project and a corresponding service account file.
- SSL certificate for the URL (`imel-project.ml.crt`, `imel-project.ml.key`).

### Installing

1. Set the `project` variable to the GCE project the system will be deployed in either in a  `terraform.tfvars` file or through the command line and then execute the following command:
   ```
   terraform apply infra/terraform
   ```

    This will create an instance to host Gitlab CI, the load balancer, the firewall rules for the Gitlab host and environment hosts, and the bucket to store the states of the environments.
  
2. Set the `external_ul` and `registry_external_url` variables in `infra/docker-compose.yml` to the Gitlab URL pointing to the IP address of the Gitlab host.
    *For this particular case, **imel-project.ml** and **registry.imel-project.ml** were registered using Freenom.*
    Then execute the following:
    ```
    ansible-playbook infra/ansible/gitlab-ci.yml
    ```
    This will install the necessary dependencies and deploy the Gitlab container onto the instance.
    After a few minutes Gitlab web UI should be available at the predefined URL.
3. Set the `reg_token` variable for the `runners.yml` playbook to the registration token from Gitlab web UI and execute:
    ```
    ansible-playbook infra/ansible/runners.yml
    ```
    This will deploy and register containers for the runners (4 by default).


## Overview
All microservice repositories belong to the [otus-project](https://imel-project.ml/otus-project) group.
Secret environment variables defined in the group:

- `GOOGLE_CREDENTIALS` - contents of a GCE json service account file;
- `GOOGLE_APPUSER_KEY` - private key for **appuser**
- `GLCOUD_PROJECT_NAME` - GCE project ID to deploy in.

### Microservices app configuration

Services used:

- **crawler** - search engine crawler. Accepts a URL as a launch parameter and puts it into the message queue, then begins to process every URL in the queue, loading the page for each, indexing it in the database and adding URLs from the page to the queue.
- **rabbitmq** - manages the message queue.
- **mongodb** - used for webpage indexing.
- **ui** - UI webpage, accepting search queries and returning indexed webpages from the database as search results. Available at port `8000` of the environment host.

Repositories:
- [ui](https://imel-project.ml/otus-project/ui/) - Search Engine UI container based on python-alpine image.
- [crawler](https://imel-project.ml/otus-project/crawler/) - Search Engine Crawler container based on python-alpine image.

### Monitoring repositories and configuration

Services used:
- **cadvisor** - exposes Docker container usage metrics. Available at port `8080`.
- **node-exporter** - exposes Docker host hardware and OS metrics.
- **blackbox-exporter** - probes **ui** and **crawler** over HTTP.
- **prometheus** - collects metrics from **cadvisor, node-exporter** and **blackbox-exporter.**
- **grafana** - visualizes metrics collected by **prometheus.**
- **alertmanager** - sends alerts on metrics collected by **prometheus.**
 
Repositories:

- [prom](https://imel-project.ml/otus-project/prom/) - Prometheus container.
- [grafana](https://imel-project.ml/otus-project/grafana/) - Grafana container. Authomaticaly provisions the Prometheus data source (see above) and dashboards.
- [alertmanager](https://imel-project.ml/otus-project/alertmanager/) - Alertmanager container. Set up to receive metrics from the Prometheus container and sends alerts to a Slack channel. The metrics monitored are "up" statuses from blackbox-exporter probes.

### Logging configuration

Services used - EFK stack:

- **fluentd**
- **elasticserach**
- **kibana**

Repositories:

- [fluentd](https://imel-project.ml/otus-project/fluentd/) - fluentd container. Configured to parse .json logs sent by **ui** and **crawler** for **kibana.**

### Deployment configuration

- [deploy](https://imel-project.ml/otus-project/deploy/) - Code for setting up the environment infrastructure and deploying the app with the prerequisites (mongodb, rabbitmq) as well as monitoring and logging services.

## CI/CD pipeline

Pipeline configuration is described in `.gitlab-ci.yml` for **ui** and **crawler** repositories.
Pipeline stages:

1. **Build** - bulding the image and pushing it to Gitlab Registry with the corresponding branch tag.
2. **Test** - running the tests on the image.
3. **Review** - creating a dynamic environment for branches other than master and deploying the microservice app along with monitoring and logging services.
4. **Cleanup** - deleting the dynamic environment, activated manually.

An environment is a GCE instance created by Terraform and provisioned by Ansible. A separate Terraform workspace is created for each dynamic environment so that it can be destroyed easily with `terraform destroy`.

Unlike docker-machine, Terraform and Ansible allow for storing the state of the environments using a remote backend and configuration check at every deployment.

**deploy** repo also contains a configuration for static environments **staging** and **production** for master branches with manual deployment.
Repositories for monitoring and logging services contain only the build stage and push to master.

## Accessing microservices
- Staging environment: `34.76.185.235`
- Production environment: `34.76.60.50`
- UI: port `8000`
- cAdvisor: port `8080`
- Prometheus: port `9090`
- Grafana: port `3000`, login `admin`, password `secret`
- Alertmanager: port `9093`
- Kibana: port `5601`

i.e. to access the search engine UI on staging environment, open `http://34.76.185.235:8000`.

## Backlog

1. An **nginx** host to provide access to environments on URL paths, i.e. `http://imel-project.ml/staging`, `http://imel-project.ml/production/monitoring` etc.
2. Proper versioning.
3. Using Docker Swarm or Kubernetes for cluster deployment.
4. Using a Google Managed SSL certificate in Terraform configuration instead of one provided beforehand.
5. Tests for this repository using Travis CI.

## Authors

* **Igor Melnikov** - [IgorMelnikov](https://github.com/IgorMelnikov)
