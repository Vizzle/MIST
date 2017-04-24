require('UIColor')

defineClass('SinglePageDemoController: MistSimpleTemplateViewController', {
	initWithScheme: function(schemeOptions) {
		self.setTemplateNames([schemeOptions.toJS()['templateName']])
		return self
	},

	viewDidLoad: function() {
		self.super().viewDidLoad()
		self.parentViewController().setTitle('Single Page')
	}
})