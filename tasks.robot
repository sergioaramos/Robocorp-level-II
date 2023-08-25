*** Settings ***
Documentation     Robot para la certificacion de Robocorp segundo nivel.
Library    RPA.Browser.Selenium  auto_close=${FALSE}
Library    RPA.HTTP    #Libreria para descargar arcivos de internet
Library    RPA.Tables    #Libreria para leer csv como tabla
Library    RPA.PDF    #Libreria para manejar archivos PDF
Library    RPA.Archive    #Libreria para manejo de archivos .zip
Library    RPA.Robocorp.Vault    #Libreria para manejar variables de entorno (Control Room)
Library    Screenshot    #Libreria para tomar screenshot


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    [Documentation]    Robot que abre un sitio web, llena un formulario y toma screenshot, y resumen en pdf de la compra.
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}    #Ciclo por el cual se recorre la tabla
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Join screenshot to pdf    ${screenshot}    ${pdf}
        Go to order another robot    #Se mueve hacia otro robot
    END
    Create a ZIP file
    [Teardown]    Close All Browsers    #Así no se ejecuten las otras keywords, esta siempre se ejecutara

*** Keywords ***
Open the robot order website
    [Documentation]    EL robot abre la página web
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    #headless=True

Get orders
    [Documentation]    El robot descaga un archivo .csv y lo lee guardandol en una variable
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV   orders.csv    header=True    delimiters=","
    RETURN    ${orders}

Close the annoying modal
    [Documentation]    Cierra el mensaje emergente
    Click Button When Visible    css:button[class="btn btn-dark"]

Fill the form
    [Documentation]    EL robot toma como argumento el archivo como tabla y lo usa para llenar el formulario
    [Arguments]    ${order}
    
    Select From List By Value    //*[@id="head"]    ${order}[Head]
    Click Element  //input[@type='radio' and @name='body' and @value='${order}[Body]']
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    //input[@name="address"]     ${order}[Address]

Preview the robot
    [Documentation]    Oprime el boton para ver el preview del robot
    Click Button    css:button[id="preview"]

Submit the order
    [Documentation]    Oprime el boton de ordenar validando que no se presente un error
    Click Button    css:button[id="order"]
    ${error}=    Does Page Contain Element    //div[@class="alert alert-danger"]
    IF    ${error}
        Submit the order
    END

PDF file
    [Documentation]    Recbe como paramétro el número de la orden. Convierte y guarda el recibo del pedido como PDF
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${order_number}_receipt.pdf

    RETURN    ${OUTPUT_DIR}${/}${order_number}_receipt.pdf

Take a screenshot of the robot
    [Documentation]    Recbe como paramétro el número de la orden. Toma un Screenshot de la orden
    [Arguments]    ${order_number}
    Screenshot    //*[@id="robot-preview-image"]    ${OUTPUT_DIR}${/}${order_number}_robot.png
    RETURN    ${OUTPUT_DIR}${/}${order_number}_robot.png
    
Join screenshot to pdf
    [Documentation]    Recibe como argumentos el Screenshot y el archivo PDF. Une el Screenshot con el archivo PDF  
    [Arguments]    ${screenshot}    ${pdf}
    ${images}=    Create List    ${screenshot}
    Add Files To Pdf    ${images}    ${pdf}    append=True

Go to order another robot
    [Documentation]    Cambia a otro robot
    Click Button    css:button[id="order-another"]

Create a ZIP file
    [Documentation]    Crea un archivo .zip en donde estan todos los pedidos
    Archive Folder With Zip    ${OUTPUT_DIR}${/}    ${OUTPUT_DIR}${/}robot_receipts.zip    include=*.pdf  exclude=/.* 

Close Browsers
    [Documentation]    Cierra todos los navegadores abiertos
    Close All Browsers
