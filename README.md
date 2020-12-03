# Subdomain-visualizer

Script that visualizes subdomains for the domain you want.

Requirements:

* [Aquatone](https://github.com/michenriksen/aquatone)
* [nmap](https://github.com/nmap/nmap)
* [SonarSearch Crobat](https://github.com/cgboal/sonarsearch/) or [SecurityTrails API key](https://securitytrails.com/)
* Active internet connection :)

## Steps the script will perform

1. Check if requirements are met

2. Get the domain the user want to parse

3. Run SonarSearch Crobat or SecurityTrails API to find subdomains or just input your own file

4. Run nmap against subdomains with the following flags '-Pn -T4'

5. Run Aquatone against results of nmap for screenshotting found ports (optionally a proxy can be used)

6. Check for compatible browsers to open the report created by Aquatone and let the user choose which browser is used

## License

MIT
