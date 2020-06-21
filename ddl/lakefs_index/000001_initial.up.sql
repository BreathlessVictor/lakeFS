-- index schema, containing information about lakeFS filesystem data
CREATE TABLE IF NOT EXISTS repositories(
                             id                varchar(64) NOT NULL PRIMARY KEY,
                             storage_namespace varchar     NOT NULL,
                             creation_date     timestamptz NOT NULL,
                             default_branch    varchar     NOT NULL
);


CREATE TABLE IF NOT EXISTS objects
(
    repository_id    varchar(64) REFERENCES repositories (id) NOT NULL,
    object_address   varchar(64)                              NOT NULL,
    checksum         varchar(64)                              NOT NULL,
    size             bigint                                   NOT NULL CHECK (size >= 0),
    physical_address varchar(64)                              NOT NULL,
    metadata         json                                     NOT NULL,

    PRIMARY KEY (repository_id, object_address)
);

CREATE TABLE IF NOT EXISTS object_dedup
(
    repository_id    varchar(64) REFERENCES repositories (id) NOT NULL,
    dedup_id         bytea                                    NOT NULL,
    physical_address varchar                                  NOT NULL,

    PRIMARY KEY (repository_id, dedup_id)
);

CREATE TABLE IF NOT EXISTS entries
(
    repository_id  varchar(64) REFERENCES repositories (id) NOT NULL,
    parent_address varchar(64)                              NOT NULL,
    name           varchar                                  NOT NULL,
    address        varchar(64)                              NOT NULL,
    type varchar(24) NOT NULL CHECK (type in ('object', 'tree')),
    creation_date timestamptz NOT NULL,
    size bigint NOT NULL CHECK(size >= 0),
    checksum varchar(64) NOT NULL,
    object_count integer,

    PRIMARY KEY (repository_id, parent_address, name)
);


CREATE TABLE IF NOT EXISTS commits
(
    repository_id varchar(64) REFERENCES repositories (id) NOT NULL,
    address       varchar(64)                              NOT NULL,
    tree          varchar(64)                              NOT NULL,
    committer     varchar                                  NOT NULL,
    message       varchar                                  NOT NULL,
    creation_date timestamptz                              NOT NULL,
    parents       json                                     NOT NULL,
    metadata      json,

    PRIMARY KEY (repository_id, address)
);


CREATE TABLE IF NOT EXISTS branches
(
    repository_id  varchar(64) REFERENCES repositories (id) NOT NULL,
    id             varchar                                  NOT NULL,
    commit_id      varchar(64)                              NOT NULL,
    commit_root    varchar(64)                              NOT NULL,
    FOREIGN KEY (repository_id, commit_id) REFERENCES commits (repository_id, address),
    PRIMARY KEY (repository_id, id)
);


CREATE TABLE IF NOT EXISTS workspace_entries
(
    repository_id       varchar(64) REFERENCES repositories (id),
    branch_id           varchar NOT NULL,
    parent_path         varchar NOT NULL,
    path                varchar NOT NULL,

    -- entry fields
    entry_name          varchar,
    entry_address       varchar(64),
    entry_type          varchar(24) CHECK (entry_type in ('object', 'tree')),
    entry_creation_date timestamptz,
    entry_size          bigint,
    entry_checksum      varchar(64),

    -- alternatively, tombstone
    tombstone           boolean NOT NULL,

    FOREIGN KEY (repository_id, branch_id) REFERENCES branches (repository_id, id),
    PRIMARY KEY (repository_id, branch_id, path)
);

CREATE INDEX IF NOT EXISTS idx_workspace_entries_parent_path ON workspace_entries (repository_id, branch_id, parent_path);


CREATE TABLE IF NOT EXISTS multipart_uploads
(
    repository_id    varchar(64) REFERENCES repositories (id) NOT NULL,
    upload_id        varchar                                  NOT NULL,
    path             varchar                                  NOT NULL,
    creation_date    timestamptz                              NOT NULL,
    physical_address varchar                                  NOT NULL,
    PRIMARY KEY (repository_id, upload_id)
);
