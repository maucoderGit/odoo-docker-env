FROM odoo:17.0

# Install debugpy for remote debugging (debug_launcher.py).
# USER root is required because the base image runs pip as the 'odoo'
# user, which would install into /var/lib/odoo/.local (hidden by the
# odoo-web volume mounted at /var/lib/odoo).
# Pin debugpy~=1.8 for VS Code / VSCodium debug adapter.
# Uses conditional install to support both Odoo 16 (no --break-system-packages)
# and Odoo 18/19+ (requires --break-system-packages for PEP 668).
USER root
RUN pip3 install --no-cache-dir "debugpy~=1.8" || pip3 install --no-cache-dir --break-system-packages "debugpy~=1.8"
USER odoo

# Install additional dependencies
# RUN pip3 install -r requirements.txt