# Otus Project

Финальный проект Otus Devops, описание  MVP.

## Установка

- `cd infra/terraform`
- Установить переменную `project` - ID проекта в GCE, где будет развёрнута инфраструктура.
- `terraform apply`
- `cd ../ansible`
- Указать соответствующий URL докер-хоста в `docker-compose.yml`.
- `ansible-playbook gitlab-ci.yml`
- Установить переменную `reg_token` - Registration token для раннеров.
- `ansible-playbook runners.yml`

## Описание CI/CD системы

Gitlab хост разворачивается на GCE с помощью Terraform, Ansible и docker-compose. Используется заранее созданный домен imel-project.ml, указывающий на IP-адрес Load Balancer.
Для registry используется registry.imel-project.ml. Поскольку на текущий момент Terraform не поддерживает Google Managed SSL Certificates, в proxy используются заранее созданный сертификат.

Для всех репозиториев настроена отправка уведомлений в Slack в канале [#igor_melnikov](https://devops-team-otus.slack.com/messages/CDCDS945V/).

Terraform создаёт:
1. Сам инстанс;
2. Необходимые правила файрволла для хоста Gitlab и хостов окружений;
3. Бакет для хранения состояния окружений. 

## Конфигурация микросервисного приложения

Все репозитории объединены в группу **otus-project** https://imel-project.ml/otus-project

В группе определены секретные переменные окружения:

- `GOOGLE_CREDENTIALS` - json-файл сервис аккаунта GCE;
- `GOOGLE_APPUSER_KEY` - файл приватного ключа appuser;
- `GCLOUD_PROJECT_NAME` - название проекта GCE.

- [ui](https://imel-project.ml/otus-project/ui/) - репозиторий Search Engine UI с добавленным Dockerfile для создания контейнера на базе python-alpine, в котором указаны переменные окружения для связи с необходимыми сервисами. Доступен на порту 8000.
 
- [crawler](https://imel-project.ml/otus-project/crawler/) - репозиторий Search Engine Crawler с добавленным Dockerfile для создания контейнера на базе python-alpine, в котором указаны переменные окружения для связи с необходимыми сервисами.
  
- [deploy](https://imel-project.ml/otus-project/deploy/) - репозиторий кода для развёртывания микросервисного приложения: компоненты ui и crawler, сервисы mongodb и rabbitmq и мониторинг.

## Конфигурация мониторинга

- [prom](https://imel-project.ml/otus-project/prom/) - репозиторий контейнера Prometheus. Для сбора метрик железа и Docker хоста используются cAdvisor (доступен на порту 8080) и node-exporter. Также настроены пробы blackbox-exporter для ui и crawler. Доступен на порту 9090.

- [grafana](https://imel-project.ml/otus-project/grafana/) - репозиторий контейнера Grafana. Настроен провиженинг datasource Prometheus (см. выше) и дэшбордов в директории `dashboards` для визуализации метрик docker, ui и crawler. Доступен на порту 3000.

- [alertmanager](https://imel-project.ml/otus-project/alertmanager/) - репозиторий контейнера alertmanager. Настроено взаимодействие с Prometheus и отправка алертов в Slack #igor_melnikov. В качестве метрик для алертинга были выбраны статусы up и пробы blackbox-exporter для инстансов ui и crawler. Доступен на порту 9093.

## Конфигурация логирования

Для логирования используется стек EFK.

- [fluentd](https://imel-project.ml/otus-project/fluentd) - репозиторий контейнера fluentd. Настроен парсинг json логов ui и crawler.

Kibana доступен на порту 5601.
  
## CI/CI пайплайн

Для репозиториев **ui** и **crawler** описана конфигурация пайплайна в `.gitlab-ci.yml`.

1. **Build** - сборка образа и пуш в Gitlab Registry с тэгом соответствующей ветки.
2. **Test** - прогон базовых тестов.
3. **Review** - поднятие динамического окружения для веток, отличных от **master** и деплой микросервисного приложения. Плейбук Ansible параметризован, чтобы для текущего репозитория использовался релиз текущей ветки (напр. feature-1), а для остальных - master. Приложение доступно по адресу инстанса окружения и порту 8000.
4. **Cleanup** - удаление динамического окружения с ручной активацией. 

Окружение представляет собой инстанс в GCE с соответствующим названием.
Terraform и Ansible были использованы для деплоя, поскольку docker-machine создаёт хост с нуля, не проверяя его состояние, и хранит конфигурацию локально, а сервера окружений должны быть сохранены между пайплайнами. Terraform хранит конфигурацию в удалённом бакенде, а Ansible проверяет необходимость внесения изменений. Для каждого окружения создаётся отдельный workspace Terraform, чтобы окружение можно было удалить `terraform destroy`.
