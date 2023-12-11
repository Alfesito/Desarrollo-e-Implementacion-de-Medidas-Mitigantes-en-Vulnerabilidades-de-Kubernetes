<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Consola Web</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f4f4f4;
        }

        header {
            background-color: #333;
            color: #fff;
            padding: 1em;
            text-align: center;
        }

        section {
            max-width: 800px;
            margin: 2em auto;
            padding: 1em;
            background-color: #fff;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }

        footer {
            background-color: #333;
            color: #fff;
            text-align: center;
            padding: 1em 0;
        }

        textarea {
            width: 100%;
            height: 150px;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>

    <header>
        <h1>Ping Web</h1>
    </header>

    <section>
        <h2>Ping a una dirección</h2>

        <form method="get" action="">
            <label for="ip_address">Ingrese la dirección:</label>
            <input type="text" name="ip_address" id="ip_address" placeholder="Ej. 0.0.0.0" required>
            <button type="submit">Ping</button>
        </form>

        <?php
        if ($_SERVER["REQUEST_METHOD"] == "GET" && isset($_GET['ip_address'])) {

            $command = "ping -c 1 ".$_GET['ip_address'];

            echo "<h2>Resultados del ping:</h2>";
            echo "<pre>";
            $output = system($command);
            
            echo "</pre>";
        }
        ?>
    </section>

    <footer>
        <p>&copy; 2023 Ping Web. Todos los derechos reservados.</p>
    </footer>

</body>
</html>
