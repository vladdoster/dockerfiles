FROM python:3.10-rc-slim-buster

RUN pip install --upgrade pip \
 && pip install mdformat \
                mdformat-toc \
                mdformat-gfm \
                mdformat-black \
                mdformat-tables

ENTRYPOINT ["python", "-m", "mdformat"] 
CMD ["-c"]
