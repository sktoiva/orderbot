*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
Library           RPA.RobotLogListener

*** Tasks ***
Order robots from the RobotSpareBin Industries website
    Open the robot order website
    Build and order robots with data from the orders file
    Create a Zip archive of the order receipts
    [Teardown]    Close the browser

*** Keywords ***
Prompt user for CSV file URL
    Add heading    Enter the CSV file URL
    Add text input    csv_url    label=URL
    ${result}=    Run dialog
    [Return]    ${result.csv_url}

Get the orders as table
    ${csv_url}=    Prompt user for CSV file URL
    Download    ${csv_url}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Open the robot order website
    ${site_config}=    Get Secret    site_config
    Log    ${site_config}
    Open Available Browser    ${site_config}[url]

Close the modal
    Click Button    OK

Fill the form for a single robot
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    Preview

Submit and wait for success
    Click Button    order
    Wait Until Page Contains Element    order-another    0.5 sec

Submit the order
    Mute Run On Failure    Submit and wait for success
    Wait Until Keyword Succeeds
    ...    6x
    ...    0.1 sec
    ...    Submit and wait for success

Order next robot
    Click Button    order-another

Export the receipt as PDF
    [Arguments]    ${order_number}
    ${pdf_filename}=    Set Variable    ${OUTPUT_DIR}${/}receipt_${order_number}.pdf
    ${image_filename}=    Set Variable    ${OUTPUT_DIR}${/}image_${order_number}.png
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Screenshot    robot-preview-image    ${image_filename}
    Html To Pdf    ${receipt_html}    ${pdf_filename}
    Add Watermark Image To Pdf
    ...    image_path=${image_filename}
    ...    source_path=${pdf_filename}
    ...    output_path=${pdf_filename}
    Close Pdf    ${pdf_filename}

Build and order robots with data from the orders file
    ${orders}=    Get the orders as table
    FOR    ${order}    IN    @{orders}
        Close the modal
        Fill the form for a single robot    ${order}
        Preview the robot
        Submit the order
        Export the receipt as PDF    ${order}[Order number]
        Order next robot
    END

Create a Zip archive of the order receipts
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}receipts.zip    include=*.pdf

Close the browser
    Close Browser
