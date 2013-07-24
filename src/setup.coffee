ncp = require('ncp').ncp

module.exports = ->
	opts = require('optimist')
		.usage('Usage: xsp --create [target] --language [language] ')
		.describe('create', 'Create an sample application')
		.alias('c', 'create')
		.describe('language', 'javascript / coffeescript')
		.alias('l', 'language')
		.describe('help', 'Show this help')
		.alias('h', 'help')
		.default('language', 'javascript')
	
	argv = opts.argv

	if argv.help
		opts.showHelp()
		return

	if argv.language is 'coffeescript'
		ncp "#{__dirname}/../setup_coffee", argv.create, (err) ->
			if err
				console.error err
			
			else
				console.log 'Done'
				
	else
		ncp "#{__dirname}/../setup", argv.create, (err) ->
			if err
				console.error err
			
			else
				console.log 'Done'