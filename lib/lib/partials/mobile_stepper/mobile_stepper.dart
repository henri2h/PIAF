import 'package:flutter/material.dart';

import 'package:minestrix_chat/partials/mobile_stepper/mobile_stepper_button.dart';

class MobileStepper extends StatefulWidget {
  final List<MStep> steps;

  const MobileStepper({Key? key, required this.steps, required this.onSend})
      : super(key: key);

  final void Function()? onSend;

  @override
  State createState() => MobileStepperState();
}

class MobileStepperState extends State<MobileStepper>
    with SingleTickerProviderStateMixin {
  TabController? _controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: widget.steps.map<Widget>((MStep e) => e.child).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: <Widget>[
            MobileStepperButton(
                enabled: _controller!.index > 0,
                children: const [
                  Icon(Icons.chevron_left),
                  Text('BACK'),
                ],
                onPressed: () {
                  _controller?.animateTo(_controller!.index - 1);
                }),
            Expanded(
              child: Center(
                child: TabPageSelector(
                    controller: _controller, selectedColor: Colors.green),
              ),
            ),
            if (_controller!.index != _controller!.length - 1)
              MobileStepperButton(
                enabled: _controller!.index < _controller!.length - 1,
                onPressed: widget.steps[_controller!.index].canContinue
                    ? () {
                        _controller!.animateTo(_controller!.index + 1);
                      }
                    : null,
                children: const [
                  Text('NEXT'),
                  Icon(Icons.chevron_right),
                ],
              ),
            if (_controller!.index == _controller!.length - 1)
              MobileStepperButton(
                enabled: true,
                onPressed: widget.onSend,
                children: const [
                  Text('SEND'),
                  SizedBox(width: 4),
                  Icon(Icons.send),
                ],
              )
          ]),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: widget.steps.length, vsync: this);
    _controller!.addListener(() {
      setState(() {});
    });
  }
}

class MStep {
  Widget child;
  bool canContinue;
  MStep(this.child, {this.canContinue = true});
}
