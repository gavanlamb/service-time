const path = require('path');
const CopyPlugin = require('copy-webpack-plugin');
const nodeExternals = require('webpack-node-externals');

module.exports = () => {
    return {
        context: path.join(__dirname, "dist"),
        mode: 'production',
        entry: "./index.js",
        target: 'node',
        optimization: {
            minimize: false
        },
        performance: {
            hints: false
        },
        output: {
            libraryTarget: 'commonjs',
            path: path.join(__dirname, 'webpack'),
            filename: 'index.js',
        },
        plugins: [
            new CopyPlugin({
                patterns:[
                    {
                        from: '../node_modules/',
                        to: "node_modules/"
                    }
                ]
            }),
        ],
        externals: [nodeExternals()]
    }
};
