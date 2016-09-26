include:
  - common.java
  - common.redis
  - common.nginx

#INSTALL AND CONFIGURE ELASTICSEARCH SERVICE
elasticsearch:
  pkg.installed:
    - sources:
      - elasticsearch: {{ salt['pillar.get']('software:elasticsearch:url') }}
  service:
    - running
    - enable: True
    - require:
      - pkg: elasticsearch
      - sls: common.java
    - watch:
        - file: /etc/elasticsearch/*

# CREATE ELASTICSEARCH CONFIGURATION FILES
/etc/elasticsearch/elasticsearch.yml:
  file.managed:
    - source: salt://common/elk-stack/files/etc/elasticsearch/elasticsearch.yml
    - require:
      - pkg: elasticsearch

/etc/elasticsearch/logging.yml:
  file.managed:
    - source: salt://common/elk-stack/files/etc/elasticsearch/logging.yml
    - require:
      - pkg: elasticsearch

#INSTALL AND CONFIGURE LOGSTASH SERVICE
logstash:
  pkg.installed:
    - sources:
      - logstash: {{ salt['pillar.get']('software:logstash:url') }}
    - require:
      - sls: common.redis
      - sls: common.java
      - pkg: elasticsearch

# CREATE LOGSTASH CONFIGURATION FILES
/etc/logstash/conf.d/logstash.conf:
  file:
    - managed
    - source: salt://common/elk-stack/files/etc/logstash/conf.d/logstash.conf
    - require:
      - pkg: elasticsearch
      - pkg: logstash

/etc/logstash/patterns:
  file.recurse:
    - source: salt://common/elk-stack/files/etc/logstash/patterns
    - include_empty: True

/etc/sysconfig/logstash:
  file.append:
    - text:
      - JAVA_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=12345 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
      - LS_OPTS="--pluginpath /opt/logstash/lib"

# CREATE AND START LOGSTASH SERVICE
configure-logstash-service:
  service.running:
    - name: logstash
    - enable: True
    - require:
      - pkg: logstash
      - file: /etc/logstash/conf.d/logstash.conf
      - sls: common.java

# INSTALL AND CONFIGURE KIBANA 4.6
kibana:
  pkg.installed:
    - sources:
      - kibana: {{ salt['pillar.get']('software:kibana:url') }}
  file.managed:
    - name: /opt/kibana/config/kibana.yml
    - source: salt://common/elk-stack/files/opt/kibana/config/kibana.yml
    - mode: 644
    - user: root
    - group: root
    - require:
      - pkg: kibana
  service.running:
    - enable: True
    - provider: service
    - watch:
      - file: /opt/kibana/config/*
    - require:
      - pkg: kibana
      - sls: common.java

/etc/nginx/locations/kibana.conf:
  file.managed:
    - source: salt://common/elk-stack/files/etc/nginx/locations/kibana.conf
    - mode: 644
    - user: root
    - group: root
    - watch_in:
      - service: nginx-service
    - require_in:
      - service: nginx-service

# ADD LOGS TO BEAVER
/etc/beaver/conf.d/elasticsearch.conf:
  file:
    - managed
    - user: root
    - group: root
    - source: salt://common/elk-stack/files/etc/beaver/conf.d/elasticsearch.conf

/etc/beaver/conf.d/logstash.conf:
  file:
    - managed
    - user: root
    - group: root
    - source: salt://common/elk-stack/files/etc/beaver/conf.d/logstash.conf

# TODO - add logs from kibana to beaver

# TURN ON LOGROTATE FOR LOGS
/etc/logrotate.d/logstash:
  file.managed:
    - source: salt://common/elk-stack/files/etc/logrotate.d/logstash

