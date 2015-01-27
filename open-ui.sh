#!/bin/bash

function master_webui_port {
  echo `docker port sparkmaster 8080` | sed 's/.*://'
}

function master_ip {
  echo `boot2docker ip`
}

open http://$(master_ip):$(master_webui_port)
