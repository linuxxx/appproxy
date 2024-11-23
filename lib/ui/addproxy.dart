import 'dart:io';

import 'package:appproxy/events/debounce.dart';
import 'package:appproxy/generated/l10n.dart';
import 'package:flutter/material.dart';

class AddProxyWidget extends StatefulWidget {
  AddProxyWidget(
      {super.key, required this.onDataFetched, required this.onData});

  // 定义一个回调，用于处理读取到的数据
  final Function(Map<String, dynamic>, {bool isAdd}) onDataFetched;
  Map<String, dynamic> onData = {};

  @override
  State<AddProxyWidget> createState() => _AddProxyWidgetState();
}

// 定义全局函数用于校验Map中所有字符串类型的值
bool isNullOrEmpty(Map<String, String> map) {
  if (map.isEmpty) {
    return true;
  }
  for (var key in map.keys) {
    if (key == "proxyUser" || key == "proxyPass") {
      continue;
    }
    if (map[key] == null || map[key]!.isEmpty) {
      return true;
    }
  }

  return false;
}

class _AddProxyWidgetState extends State<AddProxyWidget> {
  var proxyConfig = <String, String>{};
  final TextEditingController _controller_proxyName = TextEditingController();
  final TextEditingController _controller_proxyType = TextEditingController();
  final TextEditingController _controller_proxyHost = TextEditingController();
  final TextEditingController _controller_proxyPort = TextEditingController();
  final TextEditingController _controller_proxyUser = TextEditingController();
  final TextEditingController _controller_proxyPass = TextEditingController();

  final Debounce _debounce = Debounce(const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();

    if (widget.onData.isNotEmpty) {
      _controller_proxyName.text = widget.onData['proxyName'];
      _controller_proxyType.text = widget.onData['proxyType'];
      _controller_proxyHost.text = widget.onData['proxyHost'];
      _controller_proxyPort.text = widget.onData['proxyPort'];
      _controller_proxyUser.text = widget.onData['proxyUser'];
      _controller_proxyPass.text = widget.onData['proxyPass'];
    }
  }

  @override
  void dispose() {
    super.dispose();
    _debounce.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).text_add_proxy),
          // backgroundColor: const Color.fromRGBO(142, 0, 244, 1.0),
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            IconButton(
              padding: const EdgeInsets.only(right: 20.0),
              icon: const Icon(Icons.save),
              onPressed: () {
                proxyConfig['proxyName'] = _controller_proxyName.text;
                proxyConfig['proxyType'] = _controller_proxyType.text;
                proxyConfig['proxyHost'] = _controller_proxyHost.text;
                proxyConfig['proxyPort'] = _controller_proxyPort.text;
                if (isNullOrEmpty(proxyConfig)) {
                  debugPrint("proxyConfig:$proxyConfig");
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(S.of(context).text_check_parameters),
                      backgroundColor: Colors.purple.withOpacity(0.4)));
                  return;
                }
                // 这俩可以为空
                proxyConfig['proxyUser'] = _controller_proxyUser.text;
                proxyConfig['proxyPass'] = _controller_proxyPass.text;
                if (widget.onData.isNotEmpty) {
                  widget.onDataFetched(proxyConfig, isAdd: true);
                } else {
                  widget.onDataFetched(proxyConfig);
                }
                Navigator.pop(context);
              },
            )
          ],
        ),
        body: Container(
            color: Colors.purple.withOpacity(0.3),
            // 获取当前设备的屏幕高度,解决Column没有充满屏幕出现白色问题
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                // 设置UI布局中子元素的主轴线对齐方式
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextField(
                      readOnly: widget.onData.isNotEmpty,
                      controller: _controller_proxyName,
                      decoration: InputDecoration(
                        labelText: S.of(context).text_config_name,
                        border: const OutlineInputBorder(),
                      ),
                      onTap: () {
                        if (widget.onData.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  S.of(context).text_config_cannot_be_modified),
                              backgroundColor: Colors.purple.withOpacity(0.4)));
                        }
                      }),
                  const SizedBox(height: 20.0),
                  ProxyType(
                    controller: _controller_proxyType,
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    controller: _controller_proxyHost,
                    decoration: InputDecoration(
                      labelText: S.of(context).text_proxy_addr,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // 校验只能输入ip地址
                      // if (value.isNotEmpty &&
                      //     !RegExp(r'^[0-9.]+$').hasMatch(value)) {
                      //   _controller_proxyHost.text =
                      //       value.substring(0, value.length - 1);
                      // }
                      _debounce.call(context, checkConnect);
                    },
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    controller: _controller_proxyPort,
                    decoration: InputDecoration(
                      labelText: S.of(context).text_proxy_port,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // 校验只能输入数字
                      if (value.isNotEmpty &&
                          !RegExp(r'^[0-9]+$').hasMatch(value)) {
                        _controller_proxyPort.text =
                            value.substring(0, value.length - 1);
                      }
                      _debounce.call(context, checkConnect);
                    },
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    controller: _controller_proxyUser,
                    decoration: InputDecoration(
                      labelText: S.of(context).text_proxy_username,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    // 设置密码输入框的配置
                    // 控制器，用于管理输入框的文本状态
                    controller: _controller_proxyPass,
                    // 是否隐藏密码字符
                    obscureText: true,
                    // 用于隐藏密码的字符，默认为"*"
                    obscuringCharacter: "*",
                    decoration: InputDecoration(
                      // 输入框的标签文本
                      labelText: S.of(context).text_proxy_passworld,
                      // 输入框的边框样式
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            )));
  }

  void checkConnect(context) async {
    final ip = _controller_proxyHost.text;
    final port = _controller_proxyPort.text;

    if (ip.isEmpty || port.isEmpty) {
      return;
    }
    debugPrint("checkConnect:$ip:$port");
    try {
      final socket = await Socket.connect(ip, int.parse(port),
          timeout: const Duration(seconds: 1));
      socket.close();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('connect success'),
          backgroundColor: Colors.greenAccent));
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

class ProxyType extends StatefulWidget {
  const ProxyType({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<ProxyType> createState() => _ProxyTypeState();
}

enum proxyItem {
  http('http'),
  socks5('socks5');

  const proxyItem(this.label);

  final String label;
}

class _ProxyTypeState extends State<ProxyType> {
  String defaultValue = 'socks5';
  proxyItem? selectedItem;

  void onChanged(String? newValue) {
    setState(() {
      defaultValue = newValue!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<proxyItem>(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.purple[100]),
      ),
      // 设置DropdownMenu的宽度将与其父级的宽度相同
      expandedInsets: EdgeInsets.zero,
      // 设置初始选中项为_http
      initialSelection: widget.controller.text == defaultValue
          ? proxyItem.socks5
          : proxyItem.http,
      // 关联的控制器
      controller: widget.controller,
      // 点击时不自动获取焦点
      requestFocusOnTap: false,
      // 禁用搜索功能
      enableSearch: false,
      // 菜单标签
      label: Text(S.of(context).text_proxy_type),
      // 选择项时的回调
      onSelected: (proxyItem? item) {
        setState(() {
          selectedItem = item;
        });
      },
      // 生成下拉菜单项的列表
      dropdownMenuEntries:
          proxyItem.values.map<DropdownMenuEntry<proxyItem>>((proxyItem item) {
        // 为每个proxyItem生成一个DropdownMenuEntry
        return DropdownMenuEntry<proxyItem>(
          value: item, // 设置菜单项的值
          label: item.label, // 设置菜单项的显示文本
        );
      }).toList(),
    );
  }
}
