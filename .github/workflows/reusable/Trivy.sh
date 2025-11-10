    - name: Install Trivy
      uses: aquasecurity/setup-trivy@v0.2.0    

    - name: Trivy Image Scan
      run: ./.github/workflows/reusable/trivy-image-scan.sh gateway ${{ env.REGISTRY }} ${{ env.AWS_REGION }}

    - name: Upload Trivy Report
      uses: actions/upload-artifact@v4