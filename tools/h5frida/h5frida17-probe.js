/*
 * H5GG h5frida diagnostics - network JS version
 * Target: Dopamine Rootless + standalone H5GG v7.9
 * Read-only: no Gadget loading, attach, hooking, or memory changes.
 * Usage: H5GG -> Network load -> Load JS script (NOT H5 page).
 */
(function () {
  "use strict";
  var old = document.getElementById("ss-h5frida-probe");
  if (old && old.parentNode) old.parentNode.removeChild(old);

  var root = document.createElement("div");
  root.id = "ss-h5frida-probe";
  var styles = {
    position: "fixed", zIndex: "2147483647", inset: "0",
    display: "flex", alignItems: "center", justifyContent: "center",
    background: "rgba(0,0,0,.82)", padding: "10px",
    fontFamily: "-apple-system,Arial,sans-serif", color: "#f5f7ff",
    boxSizing: "border-box"
  };
  Object.keys(styles).forEach(function(k){root.style[k]=styles[k];});

  var panel = document.createElement("div");
  panel.style.cssText = "width:100%;max-width:560px;max-height:95vh;overflow:auto;background:#152435;border:1px solid #4d647d;border-radius:12px;padding:13px;box-sizing:border-box;font-size:13px;line-height:1.45";
  var title = document.createElement("div");
  title.textContent = "h5frida17 · 自编译插件诊断";
  title.style.cssText = "font-size:17px;font-weight:bold;margin-bottom:6px";
  var expl = document.createElement("div");
  expl.textContent = "只检查插件版本及进程枚举；不加载 Gadget、不附加进程、不修改内存。";
  expl.style.cssText = "opacity:.85;margin-bottom:8px";
  var output = document.createElement("pre");
  output.style.cssText = "white-space:pre-wrap;word-break:break-word;background:#0a1420;border:1px solid #334c67;padding:10px;border-radius:7px;max-height:55vh;min-height:95px;overflow:auto;color:#f3f6fc;font-size:12px;line-height:1.4;margin:8px 0";
  output.textContent = "已进入 H5GG 页面。点击「测试」开始。";
  var bar = document.createElement("div");
  bar.style.cssText = "display:flex;gap:8px;flex-wrap:wrap";
  function btn(label,bg) {
    var b=document.createElement("button");
    b.textContent=label;
    b.style.cssText="border:0;border-radius:7px;padding:10px 13px;color:white;background:"+bg+";font-size:14px;font-weight:bold;cursor:pointer;flex:1";
    return b;
  }
  var test=btn("开始测试","#2377d1");
  var close=btn("关闭","#54667b");
  bar.appendChild(test); bar.appendChild(close);
  panel.appendChild(title); panel.appendChild(expl); panel.appendChild(output); panel.appendChild(bar);
  root.appendChild(panel); document.body.appendChild(root);
  close.onclick=function(){if(root.parentNode)root.parentNode.removeChild(root);};

  function errMessage(e) {
    if(e && e.stack) return String(e.stack);
    if(e && e.message) return String(e.message);
    return String(e);
  }
  var entries=[];
  function log(s) {entries.push(String(s)); output.textContent=entries.join("\n"); output.scrollTop=output.scrollHeight;}

  test.onclick = function () {
    entries.length=0;
    test.disabled=true;
    test.textContent="测试中…";
    // Schedule the work after the UI has had an opportunity to paint.
    setTimeout(function(){
      try {
        log("模式: Dopamine Rootless / 越狱 frida-server");
        log("页面地址: "+String(window.location.href).slice(0,140));
        if(typeof h5gg==="undefined") throw new Error("缺少 h5gg API；请从 H5GG 本身加载此 JS");
        if(typeof h5gg.require==="function") h5gg.require(7.9);
        log("H5GG API: OK");
        var plug=h5gg.loadPlugin("h5frida","h5frida-17.25.0.dylib");
        if(!plug) throw new Error("loadPlugin 返回空，可能存在签名或二进制兼容问题");
        log("loadPlugin: SUCCESS");
        try{log("h5frida.pluginVersion: "+plug.pluginVersion());}catch(e){log("pluginVersion ERROR: "+errMessage(e));}
        try{log("h5frida.coreVersion: "+plug.coreVersion());}catch(e){log("coreVersion ERROR: "+errMessage(e));}
        if(plug.coreVersion && String(plug.coreVersion())!=="17.25.0") log("警告：当前加载的插件核心不是17.25.0，可能存在旧插件类缓存。");
        log("开始 enumerate_processes()，未调用 loadGadget...");
        var list=plug.enumerate_processes();
        if(!list || typeof list.length!=="number") {
          log("异常返回类型: "+Object.prototype.toString.call(list));
          log("返回内容: "+String(list));
        } else {
          log("可见进程: "+list.length+" 个");
          for(var i=0;i<Math.min(20,list.length);i++) {
            var p=list[i];
            log("  "+(i+1)+". pid="+p.pid+" name="+p.name);
          }
          if(list.length===0) log("进程列表为空。读取插件内部错误以进一步定位。");
          if(typeof plug.diagnosticLastError==="function") {
            try { log("Frida Core底层错误: "+(plug.diagnosticLastError() || "(无错误信息)")); }
            catch(e){log("读取底层错误失败: "+errMessage(e));}
          } else log("当前插件未提供 diagnosticLastError；可能仍是旧版。");
        }
      } catch(e) {
        log("ERROR: "+errMessage(e));
      } finally {
        test.disabled=false;
        test.textContent="重新测试";
      }
    },80);
  };
})();
