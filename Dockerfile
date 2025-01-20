# Base image olarak Ubuntu kullanıyoruz
FROM ubuntu:latest

# Çalışma dizinini ayarla
WORKDIR /app

# Gerekli bağımlılıkları yükle
RUN apt-get update && apt-get install -y \
    unzip \
    wget \
    curl \
    gnupg \
    python3.11 \
    python3-pip \
    git \
    openjdk-11-jre-headless \
    sudo && \
    apt-get clean

# Google Chrome yükle
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    dpkg -i google-chrome-stable_current_amd64.deb || apt-get -f install -y && \
    rm google-chrome-stable_current_amd64.deb

# Allure CLI'yi indir ve kur
RUN curl -o allure.tar.gz -L https://github.com/allure-framework/allure2/releases/download/2.21.0/allure-2.21.0.tgz && \
    tar -xzf allure.tar.gz && \
    mv allure-2.21.0 /opt/allure && \
    ln -s /opt/allure/bin/allure /usr/bin/allure && \
    rm -f allure.tar.gz

# Python bağımlılıklarını yükle
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install -r requirements.txt

# Çalışma için gerekli dosyaları kopyala
COPY . /app

# Test sonuçları ve Allure raporları için dizinleri oluştur
RUN mkdir -p features/reports/allure-results/history

# Önceki Allure history ile birleştir ve testleri çalıştır
RUN git fetch origin history-branch && \
    git checkout origin/history-branch -- features/reports/allure-results/history || echo "No previous history found" && \
    mkdir -p features/reports/allure-results && \
    behave --tags=@search -f allure_behave.formatter:AllureFormatter -o features/reports/allure-results || true && \
    cp -R features/reports/allure-results/history/* features/reports/allure-results/ || echo "No previous history to merge"

# Allure raporlarını oluştur
RUN allure generate features/reports/allure-results/ -o features/allure-report --clean

# GIT yapılandırması ve değişikliklerin history branch'e commit edilmesi
RUN git config --global user.name "GitHub Actions" && \
    git config --global user.email "actions@github.com" && \
    git add features/reports/ features/allure-report/ features/reports/allure-results/ && \
    git commit -m "Update Allure history and report" || echo "No changes to commit" && \
    git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY} && \
    git push origin history-branch --force

# Container çalıştığında varsayılan komut
CMD ["bash"]