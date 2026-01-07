FROM registry.redhat.io/rhel9/postgresql-16

USER root
RUN dnf install -y postgis35_16 && dnf clean all

USER 26
