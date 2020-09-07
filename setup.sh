#! /bin/bash
export PROJECT_ID=$(gcloud config list project --format "value(core.project)")
export IMAGE_REPO_NAME=ddsp_train
export IMAGE_TAG=gce_vm
export IMAGE_URI=eu.gcr.io/$PROJECT_ID/$IMAGE_REPO_NAME:$IMAGE_TAG
export REGION=europe-west4
export SAVE_DIR=gs://werror-2020.appspot.com/test/gce_vm
export JOB_NAME=ddsp_dist_container_job_$(date +%Y%m%d_%H%M%S)
export FILE_PATTERN=gs://werror-2020.appspot.com/mvp/data2/train.tfrecord*

apt-get remove docker docker-engine docker.io containerd runc
apt-get update
apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io

gcloud auth configure-docker -q

docker build -f Dockerfile -t $IMAGE_URI ./
docker push $IMAGE_URI

gcloud ai-platform jobs submit training $JOB_NAME \
  --region $REGION \
  --config config_single_vm.yaml \
  --master-image-uri $IMAGE_URI \
  -- \
  --save_dir=$SAVE_DIR \
  --file_pattern=$FILE_PATTERN \
  --batch_size=16 \
  --learning_rate=0.0001 \
  --num_steps=40000 \
  --early_stop_loss_value=5.0