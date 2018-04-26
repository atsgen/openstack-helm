#!/bin/bash

# Copyright 2017 The Openstack-Helm Authors.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
set -xe

#NOTE: Pull images and lint chart
make pull-images libvirt

OPENSTACK_VERSION=${OPENSTACK_VERSION:-"ocata"}
if [ "$OPENSTACK_VERSION" == "ocata" ]; then
  values="--values=./tools/overrides/releases/ocata/loci.yaml "
  values+="--values=./tools/overrides/backends/opencontrail/libvirt-ocata.yaml "
fi

HUGE_PAGES_DIR=${HUGE_PAGES_DIR:-"/dev/hugepages"}
tee /tmp/libvirt_mount.yaml << EOF
pod:
  mounts:
    libvirt:
      libvirt:
        volumeMounts:
          - name: hugepages-dir
            mountPath: $HUGE_PAGES_DIR
        volumes:
          - name: hugepages-dir
            hostPath:
              path: $HUGE_PAGES_DIR
EOF
values+="--values=/tmp/libvirt_mount.yaml "

# Insert $values to OSH_EXTRA_HELM_ARGS_LIBVIRT
OSH_EXTRA_HELM_ARGS_LIBVIRT="$values "$OSH_EXTRA_HELM_ARGS_LIBVIRT

#NOTE: Deploy command
helm upgrade --install libvirt ./libvirt \
  --namespace=openstack \
  --values=./tools/overrides/backends/opencontrail/libvirt.yaml \
  --set ceph.enabled=false \
  ${OSH_EXTRA_HELM_ARGS} \
  ${OSH_EXTRA_HELM_ARGS_LIBVIRT}

#NOTE: Wait for deploy
./tools/deployment/common/wait-for-pods.sh openstack

#NOTE: Validate Deployment info
helm status libvirt
