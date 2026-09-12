FROM odoo:17.0

# Install debugpy for remote debugging (debug_launcher.py).
# USER root is required because the base image runs pip as the 'odoo'
# user, which would install into /var/lib/odoo/.local (hidden by the
# odoo-web volume mounted at /var/lib/odoo).
# Pin ~=1.8 to stay compatible with the VS Code / VSCodium debug adapter.
# --break-system-packages: PEP 668 externally-managed guard in Odoo 18/19 images.
USER root
RUN pip3 install --no-cache-dir --break-system-packages "debugpy~=1.8"
USER odoo

# Install additional dependencies
# RUN pip3 install -r requirements.txt