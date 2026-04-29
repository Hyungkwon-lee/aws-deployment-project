#!/bin/bash
cd /home/ubuntu/scripts
docker-compose -f docker-compose.yml down || true
docker rmi -f hklee2748/aws-spring-petclinic:latest || true
