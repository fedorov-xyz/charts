# Personal Helm charts

Личный каталог Helm-чартов с семантическим версионированием в `Chart.yaml` каждого чарта.

## Установка Helm (macOS)

Рекомендуется [Homebrew](https://brew.sh):

```bash
brew install helm
helm version
```

## Структура

```
charts/
├── .github/workflows/  # lint (PR/push), release (push в GHCR)
├── redis/              # исходники чарта
│   ├── Chart.yaml      # version — версия чарта (SemVer)
│   ├── values.yaml
│   └── templates/
└── packages/           # собранные .tgz (gitignore)
```

## Версионирование и публикация

Чарты публикуются как OCI-артефакты в **GHCR**: `oci://ghcr.io/fedorov-xyz/charts/<chart>`.

1. Меняете `version` в `Chart.yaml`.
2. Мержите в `master` — workflow `release` сам соберёт `.tgz` и запушит только новые версии (существующие пропускаются).

**Первый раз** после первой публикации зайдите в GitHub → `charts` package → Package settings → Change visibility → **Public**. Иначе `helm pull` будет требовать логин.

Локальный push (нужен `GITHUB_TOKEN` с `write:packages`):

```bash
export GITHUB_TOKEN=ghp_...
make login
make push
```

## Проверка чартов

```bash
make lint    # helm lint --strict, yamllint, kubeconform
```

В CI то же самое запускает workflow `lint` на каждый PR и push в `master`.

## Установка

Пароль только через существующий Secret (чарт Secret не создаёт):

```bash
kubectl create secret generic redis-auth \
  --namespace default \
  --from-literal=password='YOUR_PASSWORD'
```

**Из GHCR (OCI):**

```bash
helm upgrade --install redis \
  oci://ghcr.io/fedorov-xyz/charts/redis --version 0.1.4 \
  --namespace default \
  --set auth.existingSecret=redis-auth
```

`helm repo add` для OCI не нужен. Список версий: `helm show chart oci://ghcr.io/fedorov-xyz/charts/redis`.

**Из исходников (локально):**

```bash
helm upgrade --install redis ./redis \
  --namespace default \
  --set auth.existingSecret=redis-auth
```

## Чарты

| Чарт  | Версия | Описание                                      |
|-------|--------|-----------------------------------------------|
| redis | 0.1.4  | Redis 8 + redis_exporter, StatefulSet + PVC   |

### redis — кастомизация

| Параметр | Описание |
|----------|----------|
| `auth.existingSecret` | Имя Secret с паролем (обязателен) |
| `auth.existingSecretPasswordKey` | Ключ в Secret (по умолчанию `password`) |
| `config` | Содержимое `redis.conf` (multiline) |
| `configmapChecksumAnnotations` | Rolling restart при смене ConfigMap (по умолчанию `true`) |
| `authChecksumAnnotations` | Rolling restart при смене `existingSecret` / ключа (по умолчанию `true`) |
| `revisionHistoryLimit` | Лимит истории StatefulSet (по умолчанию `10`) |

Схема values: `redis/values.schema.json` (валидация при `helm install` / `helm upgrade`, подсказки в IDE).

Пример с кастомным конфигом:

```bash
helm upgrade --install redis ./redis \
  -n default \
  --set auth.existingSecret=redis-auth \
  --set-file config=./my-redis.conf
```

`--set-file config=...` подставляет файл целиком в values `config`.
