function click(args) {
    var params = args.toJS()
    var button = params.button;
    var state = params.state;
    var maxLength = 9;

    if (button.type == 'clear') {
        if (state.isC) {
            state.num = '0';
            if (state.second) {
                state.num2 = state.num;
            }
            else {
                state.num1 = state.num;
            }
            state.isC = false;
        }
        else {
            state = {};
        }
    }
    else if (button.type == 'sign') {
        if (state.clear) {
            state.num = '0';
            state.clear = false;
        }
        state.num = state.num.startsWith('-') ? state.num.substring(1) : '-' + state.num;
    }
    else if (button.type == 'percent') {
        state.num = state.num / 100;
        if (state.second) {
            state.num2 = state.num;
        }
        else {
            state.num1 = state.num;
        }
    }
    else if (button.type == 'equal') {
        if (!state.op) {
            return;
        }
        if (!state.num2) {
            state.num2 = state.num1;
        }
        state.num = eval((state.num1 || state.num) + state.op + (state.num2));
        state.num1 = null;
        state.clear = true;
        state.second = false;
    }
    else if (button.type == 'point') {
        if (state.num.includes('.') || state.num.length >= maxLength) {
            return;
        }
        state.num += '.';
    }
    else if (button.op) {
        if (state.num1 && state.num2 && state.second) {
            state.num1 = state.num = eval((state.num1 || state.num) + state.op + (state.num2 || state.num));
        }
        state.num1 = state.num;
        state.second = true;
        state.op = button.op;
        state.clear = true;
    }
    else {
        state.num = (state.num == '0' || state.clear) ? button.text : (state.num == '-0' ? '-' : (state.num || '')) + button.text;
        if (state.num.replace('.', '').length > maxLength) {
            return;
        }
        if (state.second) {
            state.num2 = state.num;
        }
        else {
            state.num1 = state.num;
        }
        state.clear = false;
    }
    if (state.num && state.num != '0') {
        state.isC = true;
    }

    state.showNum = state.num ? String(state.num).replace('-', '–').replace(/\d+/, function(s) {
        return s.replace(/\d+?(?=(\d{3})+\b)/g, function(s){  
            return s +',';
        });
    }) : '0';
    
    params.mistitem.updateState(block('NSDictionary *', function(oldState) {
        return state
    }))
}

global.export(click)