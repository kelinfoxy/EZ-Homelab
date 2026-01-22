# Jupyter Lab - Data Science Environment

## Table of Contents
- [Overview](#overview)
- [What is Jupyter Lab?](#what-is-jupyter-lab)
- [Why Use Jupyter Lab?](#why-use-jupyter-lab)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Data Science IDE  
**Docker Image:** [jupyter/scipy-notebook](https://hub.docker.com/r/jupyter/scipy-notebook)  
**Default Stack:** `development.yml`  
**Web UI:** `http://SERVER_IP:8888`  
**Token:** Check container logs  
**Ports:** 8888

## What is Jupyter Lab?

Jupyter Lab is a web-based interactive development environment for notebooks, code, and data. It's the gold standard for data science work, allowing you to combine code execution, rich text, visualizations, and interactive widgets in one document. Think of it as an IDE specifically designed for data exploration and analysis.

### Key Features
- **Interactive Notebooks:** Code + documentation + results
- **Multiple Languages:** Python, R, Julia, etc.
- **Rich Output:** Plots, tables, HTML, LaTeX
- **Extensions:** Powerful extension system
- **File Browser:** Manage notebooks and files
- **Terminal:** Integrated terminal access
- **Markdown:** Rich text documentation
- **Data Visualization:** Matplotlib, Plotly, etc.
- **Git Integration:** Version control
- **Free & Open Source:** BSD license

## Why Use Jupyter Lab?

1. **Data Science Standard:** Used by data scientists worldwide
2. **Interactive:** See results immediately
3. **Documentation:** Code + explanations together
4. **Reproducible:** Share complete analysis
5. **Visualization:** Built-in plotting
6. **Exploratory:** Perfect for data exploration
7. **Teaching:** Great for learning/teaching

## Configuration in AI-Homelab

```
/opt/stacks/development/jupyter/work/
  notebooks/          # Your Jupyter notebooks
  data/              # Datasets
```

## Official Resources

- **Website:** https://jupyter.org
- **Documentation:** https://jupyterlab.readthedocs.io
- **Gallery:** https://github.com/jupyter/jupyter/wiki

## Docker Configuration

```yaml
jupyter:
  image: jupyter/scipy-notebook:latest
  container_name: jupyter
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8888:8888"
  environment:
    - JUPYTER_ENABLE_LAB=yes
    - GRANT_SUDO=yes
  user: root
  volumes:
    - /opt/stacks/development/jupyter/work:/home/jovyan/work
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.jupyter.rule=Host(`jupyter.${DOMAIN}`)"
```

**Note:** `scipy-notebook` includes NumPy, Pandas, Matplotlib, SciPy, scikit-learn, and more.

## Setup

1. **Start Container:**
   ```bash
   docker compose up -d jupyter
   ```

2. **Get Access Token:**
   ```bash
   docker logs jupyter | grep token
   # Look for: http://127.0.0.1:8888/lab?token=LONG_TOKEN_HERE
   ```

3. **Access UI:** `http://SERVER_IP:8888`
   - Enter token from logs
   - Set password (optional but recommended)

4. **Create Notebook:**
   - File → New → Notebook
   - Select kernel (Python 3)
   - Start coding!

5. **Example First Cell:**
   ```python
   import numpy as np
   import pandas as pd
   import matplotlib.pyplot as plt
   
   # Create sample data
   data = pd.DataFrame({
       'x': range(10),
       'y': np.random.randn(10)
   })
   
   # Plot
   plt.plot(data['x'], data['y'])
   plt.title('Sample Plot')
   plt.show()
   
   # Display data
   data
   ```

## Pre-installed Libraries

**scipy-notebook includes:**
- **NumPy:** Numerical computing
- **Pandas:** Data analysis
- **Matplotlib:** Plotting
- **SciPy:** Scientific computing
- **scikit-learn:** Machine learning
- **Seaborn:** Statistical visualization
- **Numba:** JIT compiler
- **SymPy:** Symbolic mathematics
- **Beautiful Soup:** Web scraping
- **requests:** HTTP library

## Summary

Jupyter Lab is your data science environment offering:
- Interactive Python notebooks
- Code + documentation + results together
- Data visualization
- Rich output (plots, tables, LaTeX)
- Pre-installed data science libraries
- Extensible architecture
- Git integration
- Free and open-source

**Perfect for:**
- Data science work
- Machine learning
- Data exploration
- Teaching/learning Python
- Research documentation
- Reproducible analysis
- Prototyping algorithms

**Key Points:**
- Notebook format (.ipynb)
- Cell-based execution
- scipy-notebook has common libraries
- Token-based authentication
- Set password for easier access
- Markdown + code cells
- Share notebooks easily

**Remember:**
- Save token or set password
- Regular notebook saves
- Export notebooks to PDF/HTML
- Version control with Git
- Install extra packages: `!pip install package`
- Restart kernel if needed
- Shutdown unused kernels

Jupyter Lab powers your data science workflow!
