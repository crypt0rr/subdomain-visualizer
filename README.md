# Subdomain-visualizer

Script that visualizes subdomains for the domain you want.

Requirements:

* [Aquatone](https://github.com/michenriksen/aquatone)
* [Nmap](https://github.com/nmap/nmap)
* [SonarSearch Crobat](https://github.com/cgboal/sonarsearch/)
* Active internet connection :)

## Steps the script will perform

1. Check if requirements are met

2. Get the domain the user want to parse

3. Run SonarSearch Crobat to find subdomains

4. Run Nmap against Crobat results with the following flags '-Pn -T4'

5. Run Aquatone against results of Nmap for screenshotting found ports (optionally a proxy can be used)

6. Check for compatible browsers to open the report created by Aquatone and let the user choose which browser is used

## License

MIT
