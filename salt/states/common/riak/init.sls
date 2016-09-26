include:
  - common.java
  - common.riak.consul

riak-ts:
  pkg.installed:
    - sources:
      - riak-ts: {{ salt['pillar.get']('software:riak-ts:url') }}

riak-ts-service:
  service:
    - name: riak
    - running
    - require:
      - pkg: riak-ts
  cmd.run:
    - name: systemctl enable riak
    - require:
      - pkg: riak-ts
