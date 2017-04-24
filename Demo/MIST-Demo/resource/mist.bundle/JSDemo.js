defineClass('JSDemoController: VZMistTemplateController', {
	myAlertMethod: function(param) {
		var alert = require('UIAlertView').alloc().initWithTitle_message_delegate_cancelButtonTitle_otherButtonTitles(param, null, null, null, 'OK', null)
		alert.show()
	}
})