# BDC – Batch Data Communication

This section contains my SAP ABAP practice work related to BDC (Batch Data Communication).

## What is BDC?

- BDC (Batch Data Communication) is a data migration technique in SAP ABAP used to transfer large amounts of data into SAP systems by simulating user interactions with SAP transaction screens.
- BDC processes data by passing values to screen fields and executing the corresponding transaction, similar to how a user enters data manually through SAP GUI.
- It is commonly used to upload data from external files, such as Excel or text files, into SAP transactions.

### Why is BDC used?
- To upload bulk data into SAP.
- To automate repetitive data-entry tasks.
- To migrate legacy data into SAP.
- To create or update business records through standard SAP transactions.
- To reduce manual data-entry effort.

### Example
Suppose a company needs to create 1,000 material master records in SAP. Instead of entering each record manually through transaction MM01, an ABAP program can read the data from a file and process it using BDC.

## BDC Methods

- [Call Transaction Method](./01-BDC/Call%20Transaction%20Method/Readme.md)
- Session Method

