#!/bin/bash -ex

# Get database password from secrets manager so it's not visible in the metadata.
PG_PASSWORD=$(gcloud secrets versions access "latest" --secret "filemage-database-password")

# Need .pgpass to avoid password prompt.
echo "database.filemage.internal:5432:filemage-db:filemage:$${PG_PASSWORD}" >> .pgpass
echo "database.filemage.internal:5432:postgres:filemage:$${PG_PASSWORD}" >> .pgpass
chmod 600 .pgpass

# Configure the pg_partman extension and associated schema.
# Ideally this would only be done once but since these
# commands are idempotent we can run this on each instance boot
# to keep the automation simple.
PGPASSFILE=.pgpass psql -h database.filemage.internal -U filemage -d filemage-db << EOF
CREATE SCHEMA IF NOT EXISTS partman;
CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman;
GRANT ALL ON SCHEMA partman TO filemage;
GRANT ALL ON ALL TABLES IN SCHEMA partman TO filemage;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA partman TO filemage;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA partman TO filemage;
EOF

PGPASSFILE=.pgpass psql -h database.filemage.internal -U filemage -d postgres << EOF
CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT cron.schedule('pg-partman-background', '30 * * * *', 'SELECT partman.run_maintenance(p_analyze := false, p_jobmon := true)');
UPDATE cron.job SET database = 'filemage-db' WHERE jobname = 'pg-partman-background';
EOF

rm .pgpass

# Each instance needs to present the same host key when accessed
# through the load balancer. For demo purposes we are going to
# use a hardcoded key, in a production environment you should
# generate a unique key.
cat > /etc/filemage/ssh_host_rsa_key << EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1C47RpCNV9g122rPLWieRr9lXvdb/duKbKXgBdJwZKbpigcC
2JOV4gUCmWJLfM7RgpbdHVgIFFVZqPgLMy5zxkzmBHfIWf1baBmbwZ1Ijktedn6X
9gfbpZU6xxy+pMwK9x+cnwpXwdXnw38a1cupDDq5NErkrwILsHwrKZz0TE1xtHuF
BsEvApFngg4jg8GhEXCKyd0uFg8R2Ex2OzY733PjokUOvWNO8A1CWtp24++aJC3A
+8Qf8FoqzWdIdjN84SK6TJd8piKMzTnUmUgPEe0OByqIJTzcLZfbgFYpzvRi9IuU
yDGIpgHBd1fkHBeRrwFNKonNpf1f5d+Kaq64yQIDAQABAoIBAQC0qbC7ArX2yBgD
fcxuA5hQ8QLle4UOf/I7VHmNO4OLkDtl1VZtBi0mx9FQvMs9t/PYV5BqPdyTQ6EW
KC2RJMpbXHq17y/ev8UmvDdNAhkXX8FM77mAOWyibpAfnbAOLdZgWMBJAst6NiIi
6YT16XVE/nNXvTU+dmVxnig6RHQWyoUE/HGJ+h1zVPH8uKG7gqYGTw4zRwQtEfOs
ruqP6g9w723W9m9c+WLj1eGH1/JBDbDugleBrMnKHqtx9glgnKbYIMjlbfApAYn+
HMlq4NerneHA3lnieovvGlFbdnBExh1M4KIhCkrlHA5n/V0xsBGio/eI8KhOhwYo
HAntbXzpAoGBAPJxQZtM5MrUP/j3iamUTf3vy6o5HXavQTXJnmtT9BPjyPCrfa6A
yGXa+ZpJ59afbE2BO+bls3jp9PTLoH1QIdRZtFlK6KK017GRcNhoqZKArU5qeK62
Dg3wfwjDm9Lu0GLCr2ndYWeoDo0kEU9qeyPmLdfvf/SSaSLGaUpyXA4jAoGBAOAL
wTyv6ERMn05BNpNxKUFWMfj9ER9GVQkttT+oUntkIjvLsxQjt+ClBkXMziKr6zNU
gikyDrpjzpUDppKr+SBFs3bXwdryj1rFk37K6zxGIgX+C04YK+eCUHNvNOwt+2sH
Av4uEz8ZUMkVjfWP0AipBrgybAbwOHSCTB3i364jAoGBAKZxjMoS20xItXa2cwNC
Nt0sgNVnisvNe+ZyedlTdNEm4/AevBVOgsYytIPxU0Ishw0auUZG0pUjgbGCDreZ
iPAheciHvfjeUOquYBuilzBmORUJ0bqYcEOvpXcd29/PZq8223jBrLqeTQcnCN9N
yiaWQ0jpOx5sWdOvBeA/bOWjAoGAVTnjfhRkRGbpSrlf62JmkSYayF5r/vugKWer
xNVg2vNSWnC4ZHbZ4aik5DRuTZ4cUGBbSxRxqdGBqgnDeZPVpsMc655TbdhLU/pI
izjhlwIOuzzSTBjBysU1mVO6TAWJ2ELIjqw0QhJ9OqDqaXkVZ9X0amkz0sfakedm
0Q+WiwUCgYA49MyrhuacUR8+PtwU4Ew2Jomf6Moq7GGjjpBM/Bnt38beaxUiDaO6
8bjwT5b73nd6LeW99G1Jv4Y4tnvvPmsuTExaLDwWgj3igehDa+YbQGCYfVcJDoVe
UH35bklU1M0U0us36GTLcwne8SzE0mcp2/03LAwFheHNIcJkRlpCSw==
-----END RSA PRIVATE KEY-----
EOF

chmod 600 /etc/filemage/ssh_host_rsa_key

# Write the database connection info to the application config.
cat > /etc/filemage/config.yml << EOF
tls_certificate: /opt/filemage/default.cert
tls_certificate_key: /opt/filemage/default.key
pg_host: database.filemage.internal
pg_user: filemage
pg_password: $${PG_PASSWORD}
pg_database: filemage-db
pg_ssl_mode: require
sftp_host_keys:
  - /etc/filemage/ssh_host_rsa_key
ftp_proxy_protocol: yes
sftp_proxy_protocol: yes
EOF

# Write the same session secret to each instance so cookies can be shared across instances.
APP_SECRET=$(gcloud secrets versions access "latest" --secret "filemage-application-secret")
echo $APP_SECRET > /opt/filemage/.secret

systemctl restart filemage

# Disable the database that comes pre-installed on the image.
systemctl stop postgresql
systemctl disable postgresql
