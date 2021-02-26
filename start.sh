#!/bin/bash

export SECRET_KEY_BASE=W68eso5YQOlbtvSNUR50N/HDWj6IaEhAwMR3LtzuBEQAefwYVbX84bvoTA7XtiGi
export MIX_ENV=prod
export PORT=4800

echo "Stopping old copy of app, if any..."

_build/prod/rel/multibulls/bin/multibulls stop || true

echo "Starting app..."

_build/prod/rel/multibulls/bin/multibulls start
