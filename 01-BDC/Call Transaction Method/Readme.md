# BDC - Call Transaction Method

The Call Transaction Method is used to upload data into SAP by executing a transaction directly from an ABAP program using the CALL TRANSACTION statement.

## What is the Call Transaction Method?
The **Call Transaction Method** executes an SAP transaction directly from an ABAP program using the `CALL TRANSACTION` statement.
The program prepares the BDC data, executes the transaction, and captures the resulting messages.

### Key characteristics
- Executes the transaction directly.
- Does not create a batch input session.
- Supports immediate processing.
- Requires program-level error handling.
- Can run with transaction screens displayed or hidden.

---

## Steps to Implement BDC – Call Transaction

### Step 1: Prepare the Source Data

Prepare the data that needs to be uploaded into SAP.

Possible sources:
- Excel file
- Text file
- Internal table
- Legacy system extract

Example:

| Material | Industry | Material Type |
|---|---|---|
| MAT1001 | M | FERT |
| MAT1002 | M | ROH |

The ABAP program reads the source data into an internal table.

### Step 2: Record the Transaction Using SHDB

Use transaction `SHDB` to record the transaction that you want to automate.

Procedure:
1. Execute transaction `SHDB`.
2. Create a new recording.
3. Enter the target transaction code, such as `MM01`.
4. Enter sample data and navigate through all required screens.
5. Save the recording.
6. Review the program names, screen numbers, field names, and navigation commands.

**Note:** Screen sequences and mandatory fields depend on the SAP system configuration. Always use a recording from the target system.

### Step 3: Declare BDC Data Structures

Declare the internal table for BDC data and the table for transaction messages.

```abap
DATA: lt_bdcdata TYPE TABLE OF bdcdata,
      ls_bdcdata TYPE bdcdata.

DATA: lt_messages TYPE TABLE OF bdcmsgcoll,
      ls_message  TYPE bdcmsgcoll.
```

**BDCDATA:** Stores the screen and field information.

**BDCMSGCOLL:** Stores messages returned during transaction processing.

### Step 4: Populate the BDC Data

The important fields of `BDCDATA` are:

| Field | Description |
|---|---|
| PROGRAM | ABAP program associated with the screen |
| DYNPRO | Screen number |
| DYNBEGIN | Marks the beginning of a screen |
| FNAM | Screen field name |
| FVAL | Value supplied to the field |

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

The program name, screen number, and field name above are illustrative. Use the actual values obtained from your transaction recording.

Include all required screens, fields, and navigation commands such as `BDC_OKCODE`.

### Step 5: Execute the Transaction

Use the `CALL TRANSACTION` statement.

```abap
CALL TRANSACTION 'MM01'
  USING lt_bdcdata
  MODE 'N'
  UPDATE 'S'
  MESSAGES INTO lt_messages.
```

#### Explanation

| Parameter | Description |
|---|---|
| USING | Supplies the BDC screen data |
| MODE 'A' | Displays all screens |
| MODE 'E' | Displays screens when an error occurs |
| MODE 'N' | Processes without displaying screens |
| UPDATE 'S' | Requests synchronous update processing |
| UPDATE 'A' | Requests asynchronous update processing |
| MESSAGES INTO | Collects transaction messages |

**Important:** `MODE 'N'` controls screen display; it does not itself schedule a background job.

### Step 6: Check the Return Code

After executing the transaction, check `SY-SUBRC`.

```abap
IF sy-subrc = 0.
  WRITE: / 'Transaction executed successfully.'.
ELSE.
  WRITE: / 'Transaction execution failed.'.
ENDIF.
```

`SY-SUBRC` should not be the only success check. Review the messages in `lt_messages` as well.

### Step 7: Handle Messages and Errors

The message table contains information such as:

| Field | Description |
|---|---|
| MSGTYP | Message type |
| MSGID | Message class |
| MSGNR | Message number |
| MSGV1–MSGV4 | Message variables |

Common message types:

- `S` – Success
- `E` – Error
- `W` – Warning
- `I` – Information
- `A` – Termination

Use the message information to create a meaningful success/error log. Standard message-formatting utilities such as `FORMAT_MESSAGE` can help convert message IDs and variables into readable text.

### Step 8: Process Multiple Records

For multiple input records, prepare and execute the BDC data separately for each record.

```abap
LOOP AT lt_input INTO ls_input.

  CLEAR lt_bdcdata.
  CLEAR lt_messages.

  "1. Populate BDC screen data
  "2. Populate field values
  "3. Add required navigation commands

  CALL TRANSACTION 'YOUR_TCODE'
    USING lt_bdcdata
    MODE 'N'
    UPDATE 'S'
    MESSAGES INTO lt_messages.

  "4. Evaluate SY-SUBRC
  "5. Review transaction messages
  "6. Log the result for the current record

ENDLOOP.
```

Replace `YOUR_TCODE` with the actual transaction code and implement the required screen data based on the SHDB recording.

---

## Advantages
- Executes transactions directly from an ABAP program.
- Does not require a batch input session.
- Allows immediate result handling.
- Supports custom error logging.
- Suitable for controlled data uploads and automated processing.

## Limitations
- Depends on the transaction's screen sequence.
- Requires appropriate error-handling logic.
- Failed records may need custom retry processing.
- Changes to screen layouts or configuration can affect the recording.
- Large uploads require careful performance and transaction management.

---

## When to Use Call Transaction

Use the Call Transaction Method when:

- The transaction should execute immediately.
- The program needs to process records one by one.
- Immediate message handling is required.
- You want to implement a custom error log.
- The upload can be controlled within a single ABAP program run.

For suitable business objects, check whether a released BAPI, standard API, or SAP migration tool is available before using screen-based BDC.

---

## Call Transaction vs. Session Method

| Feature | Call Transaction | Session Method |
|---|---|---|
| Execution | Direct | Processed from a saved session |
| Session creation | No | Yes |
| Monitoring | Custom logging | SM35 |
| Processing | Immediate | Usually deferred |
| Error handling | Program-controlled | Session monitoring and program logic |
| Suitable for | Immediate controlled uploads | Uploads needing session monitoring and recovery |

---

## Important Transactions

| Transaction | Purpose |
|---|---|
| `SHDB` | Record transaction screens for BDC |
| `SM35` | Process and monitor batch input sessions |
| `SE38` | Create and execute ABAP reports |
| `SE11` | View ABAP Dictionary definitions |

---

## Quick Revision

**Q1. What is BDC?**

BDC is a technique for transferring data into SAP by simulating transaction-screen interactions.

**Q2. What are the two BDC methods?**

1. Call Transaction Method
2. Session Method

**Q3. Which statement is used in the Call Transaction Method?**

`CALL TRANSACTION`.

**Q4. Which transaction is used to record a BDC transaction?**

`SHDB`.

**Q5. Does Call Transaction create a batch input session?**

No.

**Q6. Which structure stores BDC screen data?**

`BDCDATA`.

**Q7. Which structure collects transaction messages?**

`BDCMSGCOLL`.

**Q8. Which method is suitable for immediate transaction execution?**

Call Transaction Method.

---

## 11. Conclusion

The Call Transaction Method is useful for direct transaction processing and program-controlled error handling.

The implementation involves:

1. Preparing source data.
2. Recording the transaction using SHDB.
3. Declaring BDC data structures.
4. Populating screen and field information.
5. Executing `CALL TRANSACTION`.
6. Handling messages and errors.
7. Processing multiple records and logging results.

Understanding these steps is essential for SAP ABAP data migration and BDC interview preparation.
