# Migration Tooling Reference

> Loaded on demand from the SAP skill body. Load this file when selecting a specific AWS migration tool.

## AWS Migration Tooling

**Discover first:**
- **AWS Application Discovery Service (ADS):** agentless (VMware vCenter integration) or agent-based discovery; collects server config, performance, and process data; feeds Migration Hub.
- **AWS Migration Hub:** single pane of glass for tracking all migration activities across tools.

**Move servers:**
- **AWS Application Migration Service (MGN):** block-level continuous replication to AWS (replaces CloudEndure Migration); primary tool for Rehost; supports cutover testing without impacting source.

**Move data:**
- **AWS DataSync:** scheduled, agent-based sync for NFS/SMB shares to S3/EFS/FSx; good for ongoing sync before cutover.
- **AWS Snow Family:** offline bulk data transfer — Snowcone (8 TB usable, edge compute), Snowball Edge (80 TB usable, storage + compute), Snowmobile (100 PB, truck) — when network bandwidth makes online transfer impractical (rule of thumb: >10 TB with <1 Gbps link) `[volatile — verify live]`.
- **S3 Transfer Acceleration:** speeds up S3 PUT/GET over the public internet using CloudFront edge locations; useful when online transfer is acceptable but latency is high.
- **AWS Transfer Family:** managed SFTP/FTPS/FTP endpoint backed by S3 or EFS; for partners or systems that require file-protocol interfaces.

**Move databases:**
- **AWS Database Migration Service (DMS):** heterogeneous and homogeneous DB migrations; supports ongoing replication for near-zero-downtime cutovers.
- **AWS Schema Conversion Tool (SCT):** converts schema and application code from Oracle/SQL Server/etc. to Aurora/PostgreSQL/MySQL; run SCT before DMS for heterogeneous migrations.

**Identity for hybrid:**
- **IAM Identity Center + Active Directory:** AWS Managed Microsoft AD or AD Connector links on-premises AD to IAM Identity Center; users authenticate with existing credentials.
- **AWS Directory Service:** choose AD Connector (proxy to on-premises, no directory data in AWS) vs AWS Managed Microsoft AD (full AD in AWS, needed for trust relationships and domain-join of EC2).

**Red flag:** using DMS for a schema conversion without running SCT first (leaves incompatible objects); choosing Snow family for a 500 GB dataset with a 1 Gbps link (DataSync is faster and cheaper); forgetting to re-point DNS during cutover (causes post-migration connectivity failures).
