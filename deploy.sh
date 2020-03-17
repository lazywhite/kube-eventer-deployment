#!/bin/bash
MYSQL_IP=10.108.172.201
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_ROOT_USER=root
MYSQL_ROOT_PASSWORD=DP9bjfGg2J
MYSQL_KEVENT_USER=${MYSQL_KEVENT_USER:-kevent}
MYSQL_KEVENT_PASSWORD=${MYSQL_KEVENT_PASSWORD:-kevent}


mysql -h ${MYSQL_IP} -P ${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWORD} <<EOF
drop database if exists kube_event ;
create database kube_event;
use kube_event;


create table kube_event
(
    id               bigint(20)   not null auto_increment primary key comment 'event primary key',
    name             varchar(64)  not null default '' comment 'evenet name',
    namespace        varchar(64)  not null default '' comment 'evenet namespace',
    event_id         varchar(64)  not null default '' comment 'event_id',
    type             varchar(64)  not null default '' comment 'event type Warning or Normal',
    reason           varchar(64)  not null default '' comment 'event reason',
    message          text  not null  comment 'event message' ,
    kind             varchar(64)  not null default '' comment 'event kind' ,
    first_occurrence_time   varchar(64)    not null default '' comment 'event first occurrence time',
    last_occurrence_time    varchar(64)    not null default '' comment 'event last occurrence time',
    unique index event_id_index (event_id)
) ENGINE = InnoDB default CHARSET = utf8 comment ='Event info tables';

grant all on kube_event.* to ${MYSQL_KEVENT_USER}@'%' identified by "${MYSQL_KEVENT_PASSWORD}"
EOF



kubectl create -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    name: kube-eventer
  name: kube-eventer
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kube-eventer
  template:
    metadata:
      labels:
        app: kube-eventer
      annotations:	
        scheduler.alpha.kubernetes.io/critical-pod: ''
    spec:
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccount: kube-eventer
      containers:
        - image: registry.aliyuncs.com/acs/kube-eventer-amd64:v1.1.0-c93a835-aliyun
          name: kube-eventer
          command:
            - "/kube-eventer"
            - "--source=kubernetes:https://kubernetes.default"
            - --sink=mysql:?${MYSQL_KEVENT_USER}:${MYSQL_KEVENT_PASSWORD}@tcp(${MYSQL_IP}:${MYSQL_PORT})/kube_event?charset=utf8
          env:
          # If TZ is assigned, set the TZ value as the time zone
          - name: TZ
            value: "Asia/Shanghai" 
          volumeMounts:
            - name: localtime
              mountPath: /etc/localtime
              readOnly: true
            - name: zoneinfo
              mountPath: /usr/share/zoneinfo
              readOnly: true
          resources:
            requests:
              cpu: 100m
              memory: 100Mi
            limits:
              cpu: 500m
              memory: 250Mi
      volumes:
        - name: localtime
          hostPath:
            path: /etc/localtime
        - name: zoneinfo
          hostPath:
            path: /usr/share/zoneinfo
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-eventer
rules:
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-eventer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-eventer
subjects:
  - kind: ServiceAccount
    name: kube-eventer
    namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-eventer
  namespace: kube-system
EOF


cat > query.sh <<EOF
mysql -h ${MYSQL_IP} -u ${MYSQL_KEVENT_USER} -p${MYSQL_KEVENT_PASSWORD}  -e "select * from kube_event" kube_event
EOF
