name: Build and Push to GitHub Registry

# Configures this workflow to run every time a change is pushed to the branch called `release`.
on:
  workflow_dispatch:
  push:
    branches: ['main']

# Defines two custom environment variables for the workflow. These are used for the Container registry domain, and a name for the Docker image that this workflow builds.
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

# There is a single job in this workflow. It's configured to run on the latest available version of Ubuntu.
jobs:
  build-and-push-image:
    runs-on: ubuntu-latest
    # Sets the permissions granted to the `GITHUB_TOKEN` for the actions in this job.
    permissions:
      contents: read
      packages: write
      attestations: write
      id-token: write
      # 
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Log in to the Container registry
        uses: docker/login-action@v3.3.0
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
     
      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@v5.5.1
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}

      - name: Build and push Docker image
        id: push
        uses: docker/build-push-action@v6.5.0
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
      
      - name: Generate artifact attestation
        uses: actions/attest-build-provenance@v1.3.3
        with:
          subject-name: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME}}
          subject-digest: ${{ steps.push.outputs.digest }}
          push-to-registry: true
      
