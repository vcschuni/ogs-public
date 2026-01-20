FROM geoservercloud/geoserver-cloud-wms:2.28.1.3

# Enable standalone mode + pgconfig backend
ENV SPRING_PROFILES_ACTIVE="standalone,pgconfig"

# Optional: ACL profile if you are using geoserver-acl
# ENV SPRING_PROFILES_ACTIVE="standalone,pgconfig,acl"

# No secrets here — everything comes from OpenShift Secrets
