# pyds_custom_meta

[pybind11](https://github.com/pybind/pybind11) wrapper to access Nvidia
[DeepStream](https://developer.nvidia.com/deepstream-sdk) metadata from Python.

* Tracker meta info (`NvDsPastFrame...` classes)
* Detector and tracker bbox info (`NvDsObjectMeta.[tracker/detector]_bbox_info...` attrs) from Python.
* Analytics Metadata (`NvDsAnalyticsFrameMeta` and `NvDsAnalyticsObjInfo`) from Python.
* Also install default `pyds` precompiled library from `/opt/nvidia/deepstream/deepstream/lib`

## Installation


### Prerequisites

1. python3.6
1. Deepstream v5
1. [Option A] [pep-517](https://www.python.org/dev/peps/pep-0517/) compatible pip:

   ```console
   pip install "pip>=10"
   ```

1. [Option B] Only necessary for old `pip<10`:
   * [pybind11](https://github.com/pybind/pybind11):
     * [Option B.1] You might try simply `pip install pybind11`.
     * [Option B.2] The recommended way is to [build it from source](https://pybind11.readthedocs.io/en/stable/basics.html?highlight=install#compiling-the-test-cases)

### Install package

```console
pip install --upgrade pip>=10
pip install pyds_ext
```

## Usage

This meta-package provides three packages:

1. `pyds`: Standard pyds from `/opt/nvidia/deepstream/deepstream/lib`.
2. pyds_object_meta: Enable `NvDsObjectMeta.tracker_bbox_info...` and `NvDsObjectMeta.detector_bbox_info...` access.
3. pyds_tracker_meta: Enable `NvDsPastFrame...` access.

### Standard pyds

See oficial documentation [here](https://github.com/NVIDIA-AI-IOT/deepstream_python_apps)

### Object metadata

Use the following as a reference to extract bbox metadata:

```python
import pyds_bbox_meta

def osd_sink_pad_buffer_probe(pad, info, u_data):

    # ... code to acquire frame_meta
    l_obj=frame_meta.obj_meta_list
    while l_obj is not None:
        try:
            obj_meta=pyds_bbox_meta.NvDsObjectMeta.cast(l_obj.data)
        except StopIteration:
            break
        tracker_width = obj_meta.tracker_bbox_info.org_bbox_coords.width
        detector_width = obj_meta.detector_bbox_info.org_bbox_coords.width
        print(f"tracker_width: {tracker_width}")
        print(f"detector_width: {detector_width}")
        try: 
            l_obj=l_obj.next
        except StopIteration:
            break
        ...
```

### Tracker metadata

Ensure you have set `enable-past-frame` property of the `gst-nvtracker` plugin to `1`.
(See [nvtracker](https://docs.nvidia.com/metropolis/deepstream/dev-guide/#page/DeepStream%20Plugins%20Development%20Guide/deepstream_plugin_details.3.02.html#) plugin documentation.)

Use the following as a reference to extract tracker metadata:

```python
import pyds_tracker_meta

def osd_sink_pad_buffer_probe(pad, info, u_data):
    
    # ... code to acquire batch_meta
    
    user_meta_list = batch_meta.batch_user_meta_list
    while user_meta_list is not None:
        user_meta = pyds.NvDsUserMeta.cast(user_meta_list.data)
        
        print('user_meta:', user_meta)
        print('user_meta.user_meta_data:', user_meta.user_meta_data)
        print('user_meta.base_meta:', user_meta.base_meta)
        
        if user_meta.base_meta.meta_type != pyds.NvDsMetaType.NVDS_TRACKER_PAST_FRAME_META:
            continue
            
        pfob = pyds_tracker_meta.NvDsPastFrameObjBatch_cast(user_meta.user_meta_data)
        print('past_frame_object_batch:', pfob)
        print('  list:')
        for pfos in pyds_tracker_meta.NvDsPastFrameObjBatch_list(pfob):
            print('    past_frame_object_stream:', pfos)
            print('      streamID:', pfos.streamID)
            print('      surfaceStreamID:', pfos.surfaceStreamID)
            print('      list:')
            for pfol in pyds_tracker_meta.NvDsPastFrameObjStream_list(pfos):
                print('        past_frame_object_list:', pfol)
                print('          numObj:', pfol.numObj)
                print('          uniqueId:', pfol.uniqueId)
                print('          classId:', pfol.classId)
                print('          objLabel:', pfol.objLabel)
                print('          list:')
                for pfo in pyds_tracker_meta.NvDsPastFrameObjList_list(pfol):
                    print('            past_frame_object:', pfo)
                    print('              frameNum:', pfo.frameNum)
                    print('              tBbox.left:', pfo.tBbox.left)
                    print('              tBbox.width:', pfo.tBbox.width)
                    print('              tBbox.top:', pfo.tBbox.top)
                    print('              tBbox.right:', pfo.tBbox.height)
                    print('              confidence:', pfo.confidence)
                    print('              age:', pfo.age)
        try:
            user_meta_list = user_meta_list.next
        except StopIteration:
            break
```

### Analytics metadata

```python
import pyds_analytics_meta

def osd_sink_pad_buffer_probe(pad, info, u_data):
    
    batch_meta = pyds.gst_buffer_get_nvds_batch_meta(hash(gst_buffer))
   
    print("----NvDsAnalytics Frame Meta----") 
    
    l_frame = batch_meta.frame_meta_list 
    # Iterate over list of FrameMeta
    while l_frame is not None:
        try:
            # Casting l_frame.data to ipyds.NvDsFrameMeta
            frame_meta = pyds.NvDsFrameMeta.cast(l_frame.data)
            l_user = frame_meta.frame_user_meta_list
            while l_user is not None:
                try:
                    # Cast to NvDsUserMeta and check it either NvDsAnalyticsFrameMeta or not
                    user_meta = pyds.NvDsUserMeta.cast(l_user.data)
                    if user_meta.base_meta.meta_type != pyds.nvds_get_user_meta_type(
                            "NVIDIA.DSANALYTICSFRAME.USER_META"):
                        continue

                    user_meta_analytics = pyds_analytics_meta.NvDsAnalyticsFrameMeta.cast(user_meta.user_meta_data)
                    print('objCnt:', user_meta_analytics.objCnt)
                    print('objInROIcnt:', user_meta_analytics.objInROIcnt)
                    print('objLCCumCnt:', user_meta_analytics.objLCCumCnt)
                    print('objLCCurrCnt:', user_meta_analytics.objLCCurrCnt)
                    print('ocStatus:', user_meta_analytics.ocStatus)
                    print('unique_id:', user_meta_analytics.unique_id)
                    print(user_meta_analytics.objLCCumCnt)
                except Exception as ex:
                    print('Exception', ex)
                try:
                    l_user = l_user.next
                except StopIteration:
                    break
        except StopIteration:
            break

        print("----NvDsAnalytics Object Info----")
    
        l_obj = frame_meta.obj_meta_list
        while l_obj is not None:
            try:
                # Casting l_obj.data to pyds.NvDsObjectMeta
                obj_meta = pyds.NvDsObjectMeta.cast(l_obj.data)
                user_meta_list = obj_meta.obj_user_meta_list
                while user_meta_list is not None:
                    try:
                        user_meta = pyds.NvDsUserMeta.cast(user_meta_list.data)
                        user_meta_data = user_meta.user_meta_data
                        if user_meta.base_meta.meta_type != pyds.nvds_get_user_meta_type(
                                "NVIDIA.DSANALYTICSOBJ.USER_META"):
                            continue
                        user_meta_analytics = pyds_analytics_meta.NvDsAnalyticsObjInfo.cast(user_meta.user_meta_data)
                        print('unique_id:', user_meta_analytics.unique_id)
                        print('lcStatus:', user_meta_analytics.lcStatus)
                        print('dirStatus:', user_meta_analytics.dirStatus)
                        print('ocStatus:', user_meta_analytics.ocStatus)
                        print('roiStatus:', user_meta_analytics.roiStatus)
                    except StopIteration:
                        break
                    try:
                        user_meta_list = user_meta_list.next
                    except StopIteration:
                        break
            except StopIteration:
                break
            try:
                l_obj = l_obj.next
            except StopIteration:
                break
        
        # Get next FrameMeta in list 
        try:
            l_frame=l_frame.next
        except StopIteration:
            break
```

NOTE: see [pythiags](https://github.com/rmclabs-io/pythiags.git) for an easy-to-use API.

## References

* [tracker patch](https://forums.developer.nvidia.com/t/how-to-access-past-frame-tracking-results-from-python-in-deepstream-5-0/155245/5)
   repo also available [here](https://github.com/mrtj/pyds_tracker_meta)
* [bbox patch](https://forums.developer.nvidia.com/t/deepstream-5-0-python-api/158762/4)
* [analytics patch](https://forums.developer.nvidia.com/t/getting-metadata-of-nvdsanalyticsmeta-plugin-in-python/153546)
    repo also available [here](https://github.com/7633/pyds_analytics_meta)
