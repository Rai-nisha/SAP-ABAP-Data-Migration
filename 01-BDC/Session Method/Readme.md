# BDC - Session Method

## What is the Session Method?

The **BDC Session Method** creates a batch input session containing transaction data. The session is saved in SAP and processed separately using transaction `SM35`.

Unlike the Call Transaction Method, the Session Method does not execute each transaction immediately when the session is created.

### Key characteristics

- Creates a batch input session.
- Stores transaction data for later processing.
- Supports foreground and background processing.
- Provides session monitoring through `SM35`.
- Allows failed transactions to be investigated and reprocessed when appropriate.

---

## Steps to Implement BDC – Session Method

The Session Method follows these main steps:

1. Prepare the source data.
2. Record the transaction using `SHDB`.
3. Declare the BDC data structures.
4. Open a batch input session.
5. Populate BDC screen and field data.
6. Insert transaction data into the session.
7. Close and save the session.
8. Process the session using `SM35`.
9. Review messages and handle errors.

---

## Step 1: Prepare the Source Data

Prepare the records that need to be uploaded into SAP.

The source data may come from:

- Excel files
- Text files
- Legacy system extracts
- Internal tables

Example:

| Material | Industry | Material Type |
|---|---|---|
| MAT1001 | M | FERT |
| MAT1002 | M | ROH |
| MAT1003 | M | HALB |

Read the source data into an internal table before preparing the BDC session.

---

## Step 2: Record the Transaction Using SHDB

Use transaction `SHDB` to record the screen sequence of the SAP transaction.

### Procedure

1. Execute transaction `SHDB`.
2. Create a new recording.
3. Enter the transaction code to automate, such as `MM01`.
4. Enter sample data and navigate through the transaction screens.
5. Save the recording.
6. Review the program names, screen numbers, field names, and navigation commands.

The recording helps determine the BDC data required to execute the transaction.

**Note:** The actual screens and mandatory fields depend on your SAP system configuration. Always use a recording from the target system.

---

## Step 3: Declare BDC Data Structures

Declare the internal table used to store the screen data.

```abap
DATA: lt_bdcdata TYPE TABLE OF bdcdata,
      ls_bdcdata TYPE bdcdata.
```

### Purpose of BDCDATA

The `BDCDATA` structure contains the screen and field information needed to execute an SAP transaction.

| Field | Purpose |
|---|---|
| PROGRAM | ABAP program associated with the screen |
| DYNPRO | Screen number |
| DYNBEGIN | Marks the beginning of a screen |
| FNAM | Screen field name |
| FVAL | Field value |

---

## Step 4: Open a Batch Input Session

Use the function module `BDC_OPEN_GROUP` to open a new batch input session.

```abap
CALL FUNCTION 'BDC_OPEN_GROUP'
  EXPORTING
    group = 'Z_BDC_UPLOAD'
  EXCEPTIONS
    client_invalid         = 1
    destination_invalid    = 2
    group_invalid          = 3
    group_is_locked        = 4
    holddate_invalid       = 5
    internal_error         = 6
    queue_error            = 7
    running                = 8
    system_lock_error      = 9
    user_invalid           = 10
    OTHERS                 = 11.

IF sy-subrc <> 0.
  MESSAGE 'Unable to open BDC session' TYPE 'E'.
ENDIF.
```

### Explanation

- `BDC_OPEN_GROUP` opens the session.
- `GROUP` specifies the session name.
- The session name helps identify the batch input session in SAP.

**Important:** In a production program, handle exceptions according to the function module interface and stop processing if the session cannot be opened.

---

## Step 5: Populate the BDC Data

Prepare the BDC data for the transaction using the recording obtained from `SHDB`.

Example:

```abap
CLEAR ls_bdcdata.

ls_bdcdata-program  = 'SAPMV45A'.
ls_bdcdata-dynpro   = '0101'.
ls_bdcdata-dynbegin = 'X'.

APPEND ls_bdcdata TO lt_bdcdata.

CLEAR ls_bdcdata.

ls_bdcdata-fnam = 'VBAK-AUART'.
ls_bdcdata-fval = 'OR'.

APPEND ls_bdcdata TO lt_bdcdata.
```

### Explanation

- `PROGRAM` identifies the screen program.
- `DYNPRO` identifies the screen number.
- `DYNBEGIN = 'X'` starts a screen entry.
- `FNAM` contains the field name.
- `FVAL` contains the value to enter.

The screen and field names above are illustrative. Replace them with the values obtained from the recording of your actual transaction.

Include every required screen, field, and navigation command, such as `BDC_OKCODE`.

---

## Step 6: Insert Transaction Data into the Session

Use `BDC_INSERT` to add the transaction and its BDC data to the open session.

```abap
CALL FUNCTION 'BDC_INSERT'
  EXPORTING
    tcode     = 'MM01'
  TABLES
    dynprotab = lt_bdcdata
  EXCEPTIONS
    internal_error   = 1
    not_open         = 2
    queue_error      = 3
    tcode_invalid    = 4
    printing_invalid = 5
    posting_invalid  = 6
    OTHERS           = 7.

IF sy-subrc <> 0.
  MESSAGE 'Unable to insert transaction into session' TYPE 'E'.
ENDIF.
```

### Explanation

- `BDC_INSERT` adds one transaction to the session.
- `TCODE` specifies the transaction to execute.
- `DYNPROTAB` contains the screen and field data.

Call `BDC_INSERT` for every input record that should be included in the session.

For multiple records, prepare a fresh BDC data table for each transaction and insert it before moving to the next record.

**Important:** The example shows the core function module call. Production code should handle failures without leaving an incomplete session unmanaged.

---

## Step 7: Close and Save the Session

Use `BDC_CLOSE_GROUP` after all transaction records have been inserted.

```abap
CALL FUNCTION 'BDC_CLOSE_GROUP'
  EXCEPTIONS
    not_open    = 1
    queue_error = 2
    OTHERS      = 3.

IF sy-subrc <> 0.
  MESSAGE 'Unable to close BDC session' TYPE 'E'.
ENDIF.
```

### Explanation

`BDC_CLOSE_GROUP` closes the currently open batch input session and finalizes the session for processing.

After successfully closing the session, it can be selected for processing through transaction `SM35`.

---

## Step 8: Process the Session Using SM35

After the session has been created, execute transaction `SM35`.

### Procedure

1. Open transaction `SM35`.
2. Find the session named `Z_BDC_UPLOAD`.
3. Select the session.
4. Choose the appropriate processing option.
5. Execute the session.
6. Review the processing log and any failed transactions.

### Processing options

- **Foreground:** Displays the transaction screens while processing.
- **Background:** Processes the session without interactive screen display.
- **Display errors:** Allows failed transactions to be examined, depending on the available session-processing options.

The precise options depend on the SAP system and session status.

---

## Step 9: Handle Errors

The Session Method provides standard monitoring through `SM35`.

When an error occurs:

1. Open `SM35`.
2. Select the relevant session.
3. Review the error details.
4. Identify incorrect input data or missing mandatory fields.
5. Correct the underlying issue.
6. Reprocess failed transactions when appropriate.

### Common causes of errors

- Incorrect field values.
- Missing mandatory fields.
- Invalid screen sequence.
- Incorrect transaction code.
- Authorization problems.
- Configuration differences.
- Invalid or inconsistent source data.

Do not assume every transaction failed just because the session contains errors. Review the individual transaction results before retrying to avoid duplicate or unintended business records.

---

## Complete Session Method Flow

```text
Source Data
    |
    v
Read Input Records
    |
    v
Prepare BDCDATA
    |
    v
BDC_OPEN_GROUP
    |
    v
BDC_INSERT
    |
    v
Repeat for Each Record
    |
    v
BDC_CLOSE_GROUP
    |
    v
Process Session Using SM35
    |
    v
Review Results and Errors
```

---

## 5. Important Function Modules

| Function Module | Purpose |
|---|---|
| `BDC_OPEN_GROUP` | Opens a batch input session |
| `BDC_INSERT` | Inserts transaction data into the session |
| `BDC_CLOSE_GROUP` | Closes and finalizes the session |

These three function modules form the core of the classic BDC Session Method.

---

## Advantages of the Session Method

- Supports large, controlled data uploads.
- Separates data preparation from transaction execution.
- Provides session monitoring through `SM35`.
- Supports foreground and background processing.
- Makes it easier to investigate transaction-level errors.
- Allows failed transactions to be reprocessed where appropriate.

## Limitations of the Session Method

- Requires a separate session-processing step.
- Data is not posted merely because the session has been created.
- Depends on the transaction's screen sequence.
- Requires session management and error monitoring.
- Failed records require investigation and appropriate recovery.

---

## Session Method vs. Call Transaction Method

| Feature | Session Method | Call Transaction Method |
|---|---|---|
| Execution | Deferred until session processing | Direct transaction execution |
| Batch input session | Created | Not created |
| Main mechanism | `BDC_OPEN_GROUP`, `BDC_INSERT`, `BDC_CLOSE_GROUP` | `CALL TRANSACTION` |
| Monitoring | `SM35` | Program-level logging |
| Error handling | Session logs and custom logic | Custom program logic |
| Background processing | Session can be processed in background | Program can be scheduled separately; `MODE 'N'` only controls screen display |
| Suitable for | Uploads needing session monitoring and recovery | Immediate processing and custom result handling |

---

## Best Practices

- Validate input data before opening a session.
- Use meaningful session names.
- Test with a small set of records first.
- Handle every function module's return code and exceptions.
- Ensure the session is closed correctly.
- Keep a record of input records and processing outcomes.
- Review failed transactions before reprocessing.
- Prefer a released BAPI, standard API, or SAP migration tool when it better fits the business object and system requirements.

---

## Quick Revision for Interviews

**Q1. What is the BDC Session Method?**

It creates a batch input session containing transaction data, which can be processed separately using `SM35`.

**Q2. Which function module opens the session?**

`BDC_OPEN_GROUP`.

**Q3. Which function module inserts transaction data?**

`BDC_INSERT`.

**Q4. Which function module closes the session?**

`BDC_CLOSE_GROUP`.

**Q5. Which transaction is used to process BDC sessions?**

`SM35`.

**Q6. Does the session execute immediately when created?**

No. The session must be processed separately.

**Q7. Can a session run in the background?**

Yes. SAP supports background processing of batch input sessions.

**Q8. What is the main advantage of the Session Method?**

It provides a separate, monitorable processing workflow with session-level error analysis and recovery options.

---

## Conclusion

The BDC Session Method is useful for data migration when transaction processing needs to be separated from data preparation.

The implementation involves:

1. Preparing source data.
2. Recording the transaction using `SHDB`.
3. Declaring and populating `BDCDATA`.
4. Opening a session using `BDC_OPEN_GROUP`.
5. Inserting transactions using `BDC_INSERT`.
6. Closing the session using `BDC_CLOSE_GROUP`.
7. Processing the session using `SM35`.
8. Reviewing errors and reprocessing failed transactions where appropriate.

Understanding these steps is important for SAP ABAP development, legacy data migration, and technical interviews.
