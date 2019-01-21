---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by wanggang.
--- DateTime: 2018/9/10 9:45
--- 红点系统

if not UIBaseViewNewPoint then
    UIBaseViewNewPoint = {
        cacheNewPointTypeList = nil;    -- 加载过程中 需要显示的红点 等待加载完成后显示
        newPointList = nil;             -- 已经显示的红点
    };
end

-- region 消息更新
function UIBaseViewNewPoint:BaseRefreshNewPoint(handle,msg)
    local notifyType = msg.notifyType;
    -- 更新自己
    self:UpdateNewPoint(handle,notifyType,msg.custom1,msg.custom2,msg.custom3);
    -- 更新父亲节点
    local isAdd = NewPointNotifyData:IsAddOrRemove(notifyType);
    local faterPointList = NewPointNotifyData:GetFaterPointList(notifyType);
    self:BaseRefreshFatherNewPoint(handle,faterPointList,isAdd);
    -- 更新儿子节点
    local sonPointList = NewPointNotifyData:GetSonPointList(notifyType);
    self:BaseRefreshSonNewPoint(handle,sonPointList,isAdd,msg.custom1,msg.custom2,msg.custom3);
end
-- 递归更新
function UIBaseViewNewPoint:BaseRefreshFatherNewPoint(handle,faterPointList,isAdd)
    if faterPointList then
        for i, v in pairs(faterPointList) do
            local config = Tables.GetUIPanelNewPointTable(v);
            if config then
                local tempV = isAdd and v or (v+1);
                self:UpdateNewPoint(handle,tempV);
            end
            local tempFatherPointList = NewPointNotifyData:GetFaterPointList(v);
            self:BaseRefreshFatherNewPoint(handle,tempFatherPointList,isAdd);
        end
    end
end
function UIBaseViewNewPoint:BaseRefreshSonNewPoint(handle,sonPointList,isAdd,custom1,custom2,custom3)
    if sonPointList then
        for i, v in pairs(sonPointList) do
            local config = Tables.GetUIPanelNewPointTable(v);
            if config then
                local tempV = isAdd and v or (v+1);
                self:UpdateNewPoint(handle,tempV,custom1,custom2,custom3);
            end
            local tempSonPointList = NewPointNotifyData:GetSonPointList(v);
            self:BaseRefreshSonNewPoint(handle,tempSonPointList,isAdd,custom1,custom2,custom3);
        end
    end
end
-- endregion

-- region private
-- 打开页面时刷新所有
function UIBaseViewNewPoint:UpdateNewPointAll(handle,custom1,custom2)
    local lastNewPoints = NewPointNotifyData:GetDependViewLastNewPoint(handle._name);
    if lastNewPoints then
        for sourceNewPoint, tempLastNewPoint in pairs(lastNewPoints) do
            local sourceConfig = Tables.GetUIPanelNewPointTable(sourceNewPoint);
            if sourceConfig then
                -- 1 服务器动态
                if sourceConfig.isServer == 1 and NewPointNotifyData:IsDynamicPath(sourceConfig.path) then
                    local serverNewPointList = NewPointNotifyData:GetNotifyListByType(sourceNewPoint);
                    if serverNewPointList then
                        for i, v in pairs(serverNewPointList) do
                            self:UpdateNewPoint(handle,v.notifyType,v.custom1,v.custom2,v.custom3);
                        end
                    end
                else                                        -- 固定
                    if not custom1 and sourceConfig.param and sourceConfig.param == 0 then
                        custom1 = nil;
                    end
                    self:UpdateNewPoint(handle,sourceNewPoint,custom1,custom2);
                end
            end
        end
    end
end
-- 更新单个红点
function UIBaseViewNewPoint:UpdateNewPoint(handle,notifyType,custom1,custom2,custom3)
    local isAdd = NewPointNotifyData:IsAddOrRemove(notifyType);
    notifyType = isAdd and notifyType or notifyType - 1;

    local sourceConfig = Tables.GetUIPanelNewPointTable(notifyType);
    if not sourceConfig then
        return;
    end
    if sourceConfig.dependName ~= handle._name then
        return;
    end

    local lastNewPoints = NewPointNotifyData:GetDependViewLastNewPoint(handle._name,notifyType);
    if lastNewPoints then
        custom1 = (custom1 and custom1 ~= -1) and custom1 or nil;
        custom2 = (custom2 and custom2 ~= -1) and custom2 or nil;
        custom3 = (custom3 and custom3 ~= -1) and custom3 or nil;
        if isAdd then
            local isIn = false;
            for i, v in pairs(lastNewPoints) do
                local tempCustom1 = v == notifyType and custom1 or nil;
                local tempCustom2 = v == notifyType and custom2 or nil;
                local tempCustom3 = v == notifyType and custom3 or nil;
                if NewPointNotifyData:CheckNotify(v,tempCustom1,tempCustom2,tempCustom3) then
                    isIn = true;
                    local parentTrans,isSelect = self:GetNewPointParentTran(handle,notifyType,sourceConfig.path,custom1,custom2,custom3);
                    if isSelect then
                        self:AddNewPoint(handle,parentTrans,notifyType,custom1,custom2,custom3);
                    else
                        self:RemoveNewPoint(handle,notifyType,custom1,custom2,custom3);
                    end
                    break;
                end
            end
            if not isIn then
                self:RemoveNewPoint(handle,notifyType,custom1,custom2,custom3);
            end
        else
            local isRemove = true;
            for i, v in pairs(lastNewPoints) do
                if NewPointNotifyData:CheckNotify(v,custom1,custom2,custom3) then
                    isRemove = false;
                    break;
                end
            end
            if isRemove then
                self:RemoveNewPoint(handle,notifyType,custom1,custom2,custom3);
            end
        end
    end
end
-- 显示红点 将红点信息注册进ui中
function UIBaseViewNewPoint:AddNewPoint(handle,parentTrans,notifyType,custom1,custom2,custom3)
    if not parentTrans then
        return;
    end

    -- 判断是否已经显示了
    if self.newPointList and self.newPointList[handle._name] then
        for i, v in pairs(self.newPointList[handle._name]) do
            if parentTrans:FindChild("newPoint") and v[2] == custom1 then
                return;
            end
        end
    end

    if not FX_NEW_POINT_CAMERA and not FX_NEW_POINT_CAMERA_FLAG then
        if not self.cacheNewPointTypeList then
            self.cacheNewPointTypeList = {};
        end
        table.insert(self.cacheNewPointTypeList,{parentTrans,notifyType,custom1,custom2,custom3});
        FX_NEW_POINT_CAMERA_FLAG = true;
        CreateInstanceAsync(nil, FX_RED_POINT_PATH, true,
                function(res, instance)
                    if instance then
                        instance.gameObject:SetActive(true);
                        local tempCameraGo = instance.transform:FindChild("Camera");
                        if tempCameraGo then
                            local renderTex = UnityEngine.RenderTexture.New(128, 128, 16);
                            renderTex.name = "rex#" .. renderTex:GetInstanceID();
                            FX_NEW_POINT_CAMERA = GetComponent(tempCameraGo,"Camera");
                            FX_NEW_POINT_CAMERA.cullingMask = 2^LayerMask.NameToLayer("NGUI");
                            FX_NEW_POINT_CAMERA.enabled = true;
                            FX_NEW_POINT_CAMERA.targetTexture = renderTex;
                        end
                    end
                    if self.cacheNewPointTypeList then
                        for i, v in pairs(self.cacheNewPointTypeList) do
                            self:AddNewPointCore(handle,v[1],v[2],v[3],v[4],v[5]);
                        end
                        self.cacheNewPointTypeList = nil;
                    end
                end);
    else
        if FX_NEW_POINT_CAMERA then
            self:AddNewPointCore(handle,parentTrans,notifyType,custom1,custom2,custom3);
        else
            if self.cacheNewPointTypeList then
                table.insert(self.cacheNewPointTypeList,{parentTrans,notifyType,custom1,custom2,custom3});
            end
        end
    end
end
-- 创建红点
function UIBaseViewNewPoint:AddNewPointCore(handle,parentTrans,notifyType,custom1,custom2,custom3)
    if not FX_NEW_POINT_CAMERA then
        return;
    end
    if not notifyType then
        return;
    end
    local config = Tables.GetUIPanelNewPointTable(notifyType);
    if not config then
        return;
    end

    local newPointGo = GameObject.New("newPoint");
    local newPointTrans = newPointGo.transform;
    newPointGo.layer = UnityEngine.LayerMask.NameToLayer("NGUI");
    newPointTrans.parent = parentTrans;
    newPointTrans.localPosition = Vector3.New(config.offset_x,config.offset_y,0);
    newPointTrans.localScale = Vector3.New(1,1,1);
    local newPointText = newPointGo:AddComponent(UITexture.GetClassType());
    if newPointText then
        newPointText.width = 44;
        newPointText.height = 44;
        newPointText.depth = config.depth;
        newPointText.mainTexture = FX_NEW_POINT_CAMERA.targetTexture;
    end
    if not self.newPointList then
        self.newPointList = {};
    end
    local handleName = handle._name;
    if not self.newPointList[handleName] then
        self.newPointList[handleName] = {};
    end
    table.insert(self.newPointList[handleName],{notifyType,custom1,custom2,custom3,newPointGo});
end
-- 销毁红点 这里有点问题 导致频繁的创建和销毁 需要优化一下
function UIBaseViewNewPoint:RemoveNewPoint(handle,notifyType,custom1,custom2,custom3)
    if self.newPointList and handle and self.newPointList[handle._name] then
        local handleName = handle._name;
        if notifyType then
            for i, v in pairs(self.newPointList[handleName]) do
                if handleName == ViewConst.UIPanel_ChapterRealStage then
                    custom1, custom2 = LevelData:AnalysChapterStageId(custom1);
                end
                if v[1] == notifyType and v[2] == custom1 and v[3] == custom2 and v[4] == custom3 then
                    Object.Destroy(v[5]);
                    table.remove(self.newPointList[handleName],i);
                    if table.Getlen(self.newPointList[handleName]) == 0 then
                        self.newPointList[handleName] = nil;
                    end
                    break;
                end
            end
        else
            if handleName~=ViewConst.UIPanel_ChapterRealStarBox then
                for i, v in ipairs(self.newPointList[handleName]) do
                    Object.Destroy(v[5]);
                end
                table.clear(self.newPointList[handleName]);
                self.newPointList[handleName] = nil;
            end
        end
    end
end
--[[ 节点的寻找 有两种
    1 固定位置 直接配表
    2 动态位置 需要当前页面提供接口
--]]
function UIBaseViewNewPoint:GetNewPointParentTran(handle,notifyType,path,custom1,custom2,custom3)
    local trans = nil;
    local isSelect = true;
    custom1 = custom1 and custom1 or NewPointNotifyData:GetNewPointConfigValue(notifyType,"param");
    local dependName = NewPointNotifyData:GetNewPointConfigValue(notifyType,"dependName");
    -- 后续红点
    if NewPointNotifyData:IsAfterNewPoint(notifyType) then
        local fatherNewPointList = NewPointNotifyData:GetFatherNewpointList(notifyType);
        if fatherNewPointList then
            for i, v in pairs(fatherNewPointList) do
                local isBreak = false;
                local serverNewPointList = NewPointNotifyData:GetNotifyListByType(v);
                if serverNewPointList then
                    for j, vj in pairs(serverNewPointList) do
                        trans , isSelect = self:GetDynamicNewPoint(dependName,path,notifyType,vj.custom1,vj.custom2,vj.custom3);
                        if isSelect then
                            isBreak = true;
                            break;
                        end
                    end
                end
                if isBreak then
                    break;
                end
            end
        end
        -- 动态红点
    else
        local dynamic = NewPointNotifyData:IsDynamicPath(path);
        if dynamic then
            trans , isSelect = self:GetDynamicNewPoint(dependName,path,notifyType,custom1,custom2,custom3);
            -- 固定红点
        else
            trans , isSelect = self:GetPreNewPoint(handle,path,custom1,custom2,custom3);
        end
    end
    return trans , isSelect;
end
-- endregion
-- region public
-- 动态 红点
function UIBaseViewNewPoint:GetDynamicNewPoint(dependName,path,notifyType,param,param2,param3)
    local trans = nil;
    local isSelect = true;

    if dependName == ViewConst.UIPanel_Mainmap then                             -- 主界面页签红点
        local tempParam = tonumber(param);
        trans = UIMainMapManager:GetNewPointNode(path,tempParam);
    elseif dependName == ViewConst.UIPanel_RoleMain_Equip then                  -- 装备列表红点
        local tempParam = tonumber(param)-1;
        trans = RoleManager:GetNewPointNode(path,tempParam);
    elseif dependName == ViewConst.UIPanel_RoleEquipDetailReal then             -- 装备详情红点
        local equipType = tonumber(param) or 0;
        trans,isSelect = RoleEquipManager:GetNewPointNode(path,equipType);
    elseif dependName == ViewConst.UIPanel_PetList then
        local tempParam=tonumber(param);
        trans,isSelect= PetManager:GetNewPointNode(tempParam);
    elseif dependName == ViewConst.UIPanel_PetReal then
        local slot = tonumber(param) or 0;
        trans,isSelect = PetManager:GetRedPointNode(path,slot);
    elseif dependName == ViewConst.UIPanel_Chat then
        local playerId=tonumber(param);
        trans = ChatManager:GetNewPointNode(playerId);
    elseif dependName == ViewConst.UIPanel_WeaponTechTreeReal_Skill then
        local tempParam = tonumber(param);
        if notifyType ==17 then
           trans,isSelect=RoleWeaponManager:GetNode(path,tempParam);
        else
           trans = RoleWeaponManager:GetNewPointNode(path,tempParam);
        end
    elseif dependName == ViewConst.UIPanel_ChapterRealMap then
        local tempParam = tonumber(param);
        trans,isSelect = UILevelManager:GetChaperNode(notifyType,path,tempParam);
    elseif dependName == ViewConst.UIPanel_ChapterRealStage then
        local tempParam=tonumber(param);
        trans,isSelect= UILevelManager:GetdiffNode(notifyType,path,tempParam);
    elseif dependName == ViewConst.UIPanel_ChapterRealStarBox then
        local tempParam=tonumber(param);
        trans,isSelect = UILevelManager:GetStageNode(tempParam);
    elseif dependName == ViewConst.UIPanel_RoleWeaponReal_Skill then
        local tempParam=tonumber(param);
        if notifyType==21 then
            trans = RoleWeaponManager:GetSkillNode(path,tempParam+1);
        else
            trans = RoleWeaponManager:GetSkillPartNode(path,tempParam);
        end
    elseif dependName == ViewConst.UIPanel_RoleMain_Attr then
        trans = RoleManager:GetRedPointNode(path);
    elseif dependName == ViewConst.UIPanel_CreateAward then
        local tempParam=tonumber(param);
        trans = LevelActivityManager:GetRedPointNode(path,tempParam);
    elseif dependName ==ViewConst.UIPanel_PetChapterSelect then
        local tempParam=tonumber(param);
        local param2=tonumber(param2);
        trans,isSelect = PetManager:GetJuQingNode(path,tempParam,param2);
    elseif dependName == ViewConst.UIPanel_PetChapterCard then
        local param=tonumber(param);
        local param2=tonumber(param2);
        trans,isSelect= PetManager:GetCardNode(path,param,param2);
    elseif dependName == ViewConst.UIPanel_PetEquip then
        local param = tonumber(param);
        trans,isSelect=PetManager:GetPetPartNode(path,param);
    elseif dependName == ViewConst.UIPanel_PetTalent then
        local param=tonumber(param);
        local param2=tonumber(param2);
        trans,isSelect = PetManager:GetTalentNode(path,param,param2);
    end
    return trans,isSelect;
end
-- 静态红点
function UIBaseViewNewPoint:GetPreNewPoint(handle,path)
    local trans = nil;
    local isSelect = true;
    if LevelManager.enterGameSceneType ~= EnterGameSceneType.Building then
        trans = handle._transform:FindChild(path);
    end
    return trans,isSelect;
end
-- endregion