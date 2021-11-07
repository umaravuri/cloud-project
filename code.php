<html> 
    <head> 
        <title>My website</title> 
    </head> 
    <body> 
        <pre>
        <?php
        $filename = "/var/www/html/domain_name.txt" ;
        $file = fopen( $filename , "r");
        $filesize = filesize( "domain_name.txt" );
        $domain_name = fread($file , $filesize);
        fclose( $file );
        echo   "<h1>WELCOME !!</h1>";
        echo   "<h2>This is UMA RAVURI and SAI SUCHETAN</h2>";
        echo   "<img src='http://{$domain_name}/cloud.jpg'   width='390'   height='712'     />";
        ?>
        </pre>
    </body> 
</html>                     
