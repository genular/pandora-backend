/**
This file is used as pm2 process manager configuration file

R_CONFIG_ACTIVE = "production"
pm2 start ecosystem.config.js --only simon-analysis
pm2 start ecosystem.config.js --only simon-general
pm2 start ecosystem.config.js --only simon-plots

pm2 status
pm2 logs --raw simon-general
*/

const backendPath = PLACEHOLDER;

const ignoreWatch = [
    "[/\\]./",
    "documentation",
    "cron",
    "SHARED_DATA",
    "*.config.js",
    "*.yml",
    ".Rhistory",
    ".Rprofile",
    "*.md",
    "*.pid",
    "Rplots*",
    "server/backend/*",
    "logs",
    "*.log",
    "*.php",
    ".git"
];

const watchOptions = {
    usePolling: true,
    alwaysStat: true,
    useFsEvents: false
};

module.exports = {
    apps: [
        {
            name: "simon-analysis",
            cwd: backendPath,
            script: "./server/analysis/index.R",
            args: "analysis",
            watch: true,
            ignore_watch: ignoreWatch,
            watch_options: watchOptions,
            interpreter: "/usr/bin/Rscript",
            env: {
                NODE_ENV: "development"
            }
        },
        {
            name: "simon-plots",
            cwd: backendPath,
            script: "./server/plots/index.R",
            args: "plots",
            watch: true,
            ignore_watch: ignoreWatch,
            watch_options: watchOptions,
            interpreter: "/usr/bin/Rscript",
            env: {
                NODE_ENV: "development"
            }
        }
        // {
        //     name: "simon-analysis-python",
        //     cwd: backendPath,
        //     script: "./server/python/run.py",
        //     args: "analysis-python",
        //     watch: ["server/python"],
        //     watch_options: watchOptions,
        //     interpreter: "/usr/bin/python3.7"
        // }
    ]
};
